public with sharing class RoomBookingAction {

    // ==== INPUT DTO ====
    public class Request {
        @InvocableVariable(required=true)
        public Id workTypeId;          // The Scheduler Work Type (e.g. 60 Minute Booking)

        @InvocableVariable(required=true)
        public Id serviceTerritoryId;  // Territory (e.g. Building A)

        @InvocableVariable(required=true)
        public Id serviceResourceId;   // The room's ServiceResource Id

        @InvocableVariable(required=true)
        public Datetime start;         // Slot start time (UTC Datetime)

        @InvocableVariable(required=true)
        public Datetime d_end;           // Slot end time (UTC Datetime)

        @InvocableVariable
        public Id parentRecordId;      // Optional: Account / Case / Opportunity / custom parent

        @InvocableVariable
        public String subject;         // Optional subject for the appointment

        @InvocableVariable
        public String description;     // Optional description / notes
    }

    // ==== OUTPUT DTO ====
    public class Result {
        @InvocableVariable
        public Id serviceAppointmentId;

        @InvocableVariable
        public String appointmentNumber;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String confirmationMessage;
    }

    /**
     * Books a room by:
     * 1) Optionally checking for overlapping appointments for the same room.
     * 2) Creating a ServiceAppointment.
     * 3) Creating an AssignedResource linking the appointment to the room.
     *
     * This method is designed to be exposed as an Agent Action or called from Flow.
     */
    @InvocableMethod(label='Book Room Appointment'
                     description='Create a ServiceAppointment and AssignedResource for a room slot')
    public static List<Result> bookRoomAppointments(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request r : requests) {

            // ---- Basic sanity check ----
            if (r.start == null || r.d_end == null || r.start >= r.d_end) {
                Result invalid = new Result();
                invalid.status = 'ERROR';
                invalid.confirmationMessage =
                    'Invalid time window: start must be before end.';
                results.add(invalid);
                continue;
            }

            // ---- Overlap check (same room, overlapping non-cancelled appointment) ----
            List<AssignedResource> existing = [
                SELECT Id,
                       ServiceAppointmentId,
                       ServiceResourceId,
                       ServiceAppointment.SchedStartTime,
                       ServiceAppointment.SchedEndTime,
                       ServiceAppointment.Status
                FROM AssignedResource
                WHERE ServiceResourceId = :r.serviceResourceId
                  AND ServiceAppointment.SchedStartTime < :r.d_end
                  AND ServiceAppointment.SchedEndTime   > :r.start
                  AND ServiceAppointment.Status != 'Cancelled'
                LIMIT 1
            ];

            if (!existing.isEmpty()) {
                Result conflict = new Result();
                conflict.status = 'CONFLICT';
                conflict.confirmationMessage =
                    'Room is already booked in the requested window.';
                results.add(conflict);
                continue;
            }

            // ---- Create the ServiceAppointment ----
            ServiceAppointment sa = new ServiceAppointment();
            sa.WorkTypeId         = r.workTypeId;
            sa.ServiceTerritoryId = r.serviceTerritoryId;
            sa.ParentRecordId     = r.parentRecordId;

            sa.SchedStartTime     = r.start;
            sa.SchedEndTime       = r.d_end;

            // Optional: ArrivalWindowStartTime/EndTime if you use windows
            // sa.ArrivalWindowStartTime = r.start;
            // sa.ArrivalWindowEndTime   = r.end;

            sa.Subject            = String.isBlank(r.subject)
                                    ? 'Room booking'
                                    : r.subject;
            sa.Description        = r.description;

            // Adjust to your org’s status values (“Scheduled”, “New”, etc.)
            sa.Status             = 'Scheduled';

            insert sa;

            // ---- Create the AssignedResource linking the room to the appointment ----
            AssignedResource ar = new AssignedResource();
            ar.ServiceAppointmentId = sa.Id;
            ar.ServiceResourceId    = r.serviceResourceId;
            ar.Role                 = 'Primary';  // or a custom role name in your org

            insert ar;

            // ---- Build result ----
            Result res = new Result();
            res.serviceAppointmentId = sa.Id;
            res.appointmentNumber    = sa.AppointmentNumber;
            res.status               = sa.Status;
            res.confirmationMessage  =
                'Booked room from ' +
                String.valueOf(r.start) +
                ' to ' +
                String.valueOf(r.d_end) +
                '. Appointment Number: ' +
                sa.AppointmentNumber;

            results.add(res);
        }

        return results;
    }
}
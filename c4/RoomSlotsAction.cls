public with sharing class RoomSlotsAction {

    public class Request {
        @InvocableVariable(required=true)
        public Id workTypeGroupId;
        @InvocableVariable(required=true)
        public Id serviceTerritoryId;
        @InvocableVariable(required=true)
        public Datetime start;
        @InvocableVariable(required=true)
        public Datetime d_end;
        @InvocableVariable
        public Id schedulingPolicyId;
        @InvocableVariable
        public Id accountId;
    }

    public class Candidate {
        @InvocableVariable
        public Datetime startTime;

        @InvocableVariable
        public Datetime endTime;

        @InvocableVariable
        public List<String> resources;

        @InvocableVariable
        public String territoryId;
    }
    
        @InvocableMethod(label='Find room slots')
    public static List<Candidate> find(List<Request> reqs) {
        Request r = reqs[0];

        String startIso = r.start.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        String endIso   = r.d_end.format('yyyy-MM-dd\'T\'HH:mm:ssZ');

        lxscheduler.GetAppointmentCandidatesInput input =
            new lxscheduler.GetAppointmentCandidatesInputBuilder()
                .setWorkTypeGroupId((String) r.workTypeGroupId)
                .setTerritoryIds(new List<String>{ (String) r.serviceTerritoryId })
                .setStartTime(startIso)
                .setEndTime(endIso)
                .setAccountId(r.accountId == null ? null : (String) r.accountId)
                .setSchedulingPolicyId(
                    r.schedulingPolicyId == null ? null : (String) r.schedulingPolicyId
                )

                .build();

        String response = lxscheduler.SchedulerResources.getAppointmentCandidates(input);

        if (String.isBlank(response)) {
            return new List<Candidate>();
        }

        List<Candidate> candidates =
            (List<Candidate>)JSON.deserialize(response, List<Candidate>.class);

        return candidates;
    }
}
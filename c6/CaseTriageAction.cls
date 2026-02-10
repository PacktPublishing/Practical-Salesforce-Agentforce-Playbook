public class CaseTriageAction {
  @InvocableMethod(
    label='Triage Case'
    description='Evaluates case priority and suggests routing based on case details'
  )
  public static List<TriageResponse> triage(List<TriageRequest> requests) {
    List<TriageResponse> responses = new List<TriageResponse>();
    for (TriageRequest req : requests) {
      TriageResponse res = new TriageResponse();
      res.suggestedPriority = determinePriority(
        req.caseSubject,
        req.caseDescription
      );
      res.suggestedQueue = determineQueue(
        req.caseSubject,
        req.caseDescription,
        req.caseOrigin
      );
      res.requiresEscalation = checkEscalation(
        req.caseSubject,
        req.caseDescription
      );
      res.triageNotes = generateTriageNotes(res);
      responses.add(res);
    }
    return responses;
  }
  private static String determinePriority(String subject, String description) {
    String combined = (subject + ' ' + description).toLowerCase();
    if (
      combined.contains('critical') ||
      combined.contains('emergency') ||
      combined.contains('system down')
    ) {
      return 'Critical';
    } else if (
      combined.contains('urgent') ||
      combined.contains('asap') ||
      combined.contains('important')
    ) {
      return 'High';
    } else if (
      combined.contains('question') ||
      combined.contains('inquiry') ||
      combined.contains('information')
    ) {
      return 'Low';
    }
    return 'Medium';
  }
  private static String determineQueue(
    String subject,
    String description,
    String origin
  ) {
    String combined = (subject + ' ' + description).toLowerCase();
    if (
      combined.contains('billing') ||
      combined.contains('invoice') ||
      combined.contains('payment')
    ) {
      return 'Billing Support';
    } else if (
      combined.contains('technical') ||
      combined.contains('error') ||
      combined.contains('bug')
    ) {
      return 'Technical Support';
    } else if (
      combined.contains('sales') ||
      combined.contains('pricing') ||
      combined.contains('quote')
    ) {
      return 'Sales Team';
    }
    return 'General Support';
  }
  private static Boolean checkEscalation(String subject, String description) {
    String combined = (subject + ' ' + description).toLowerCase();
    return combined.contains('escalate') ||
      combined.contains('manager') ||
      combined.contains('legal') ||
      combined.contains('critical');
  }
  private static String generateTriageNotes(TriageResponse res) {
    String notes =
      'Auto-triaged: Priority=' +
      res.suggestedPriority +
      ', Queue=' +
      res.suggestedQueue;
    if (res.requiresEscalation) {
      notes += ' [ESCALATION RECOMMENDED]';
    }
    return notes;
  }
  public class TriageRequest {
    @InvocableVariable(label='Case Subject' required=true)
    public String caseSubject;
    @InvocableVariable(label='Case Description' required=true)
    public String caseDescription;
    @InvocableVariable(label='Case Origin')
    public String caseOrigin;
  }
  public class TriageResponse {
    @InvocableVariable(label='Suggested Priority')
    public String suggestedPriority;
    @InvocableVariable(label='Suggested Queue')
    public String suggestedQueue;
    @InvocableVariable(label='Requires Escalation')
    public Boolean requiresEscalation;
    @InvocableVariable(label='Triage Notes')
    public String triageNotes;
  }
}
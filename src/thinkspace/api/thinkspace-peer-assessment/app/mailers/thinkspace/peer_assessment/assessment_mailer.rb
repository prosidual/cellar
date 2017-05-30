module Thinkspace; module PeerAssessment
  class AssessmentMailer < Thinkspace::Common::BaseMailer
    skip_after_action :prevent_delivery, only: [:notify_results_unlocked, :notify_assessment_reminder, :notify_assessment_unlocked]

    def notify_results_unlocked(assessment, user)
      @to         = user
      @phase      = assessment.overview_phase
      @assignment = @phase.thinkspace_casespace_assignment

      raise "Cannot send a notification without an email [#{@to}]." unless @to.present?
      raise "Cannot send a notification without a phase [#{@phase}]." unless @phase.present?
      raise "Cannot send a notification without an assignment [#{@assignment}]." unless @assignment.present?

      @url    = phases_show_url(@assignment, @phase)
      subject = "The results of your peer evaluation #{@assignment.title} are now available"
      mail(to: @to.email, subject: format_subject(subject))
    end

    def notify_assessment_reminder(review_set)
      @to         = review_set.ownerable
      @phase      = review_set.get_authable
      @assignment = @phase.thinkspace_casespace_assignment

      raise "Cannot send a notification without an email [#{@to}]." unless @to.present?
      raise "Cannot send a notification without a phase [#{@phase}]." unless @phase.present?
      raise "Cannot send a notification without an assignment [#{@assignment}]." unless @assignment.present?

      @url    = phases_show_url(@assignment, @phase)
      subject = "Your evaluations for #{@assignment.title} are pending"
      mail(to: @to.email, subject: format_subject(subject))
    end

    def notify_assessment_unlocked(assessment, user)
      @to         = user
      @phase      = assessment.authable
      @assignment = @phase.thinkspace_casespace_assignment

      raise "Cannot send a notification without an email [#{@to}]." unless @to.present?
      raise "Cannot send a notification without a phase [#{@phase}]." unless @phase.present?
      raise "Cannot send a notification without an assignment [#{@assignment}]." unless @assignment.present?

      @url    = phases_show_url(@assignment, @phase)
      subject = "You must re-submit your peer evaluation #{@assignment.title}"
      mail(to: @to.email, subject: format_subject(subject))
    end

    def phases_show_url(assignment, phase)
      format_url("cases/#{assignment.id}/phases/#{phase.id}?query_id=none")
    end

  end
end; end;
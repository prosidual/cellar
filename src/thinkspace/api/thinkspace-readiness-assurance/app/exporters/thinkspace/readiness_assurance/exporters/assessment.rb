require 'spreadsheet'

module Thinkspace; module ReadinessAssurance; module Exporters; class Assessment < Thinkspace::Common::Exporters::Base
  attr_reader :caller, :assessment, :phase, :assignment, :teams, :users, :team_sets, :review_sets, :reviews

  def initialize(caller, assessment, phase, teams)
    @caller     = caller
    @assessment = assessment
    @phase      = phase
    @assignment = phase.thinkspace_casespace_assignment
    @teams      = teams
    @users      = phase.get_space.thinkspace_common_users.order(:last_name).uniq
    @responses  = @assessment.thinkspace_readiness_assurance_responses
  end

  def process
    book   = caller.get_book_for_record(@phase)
    sheet  = caller.find_or_create_worksheet_for_phase(book, @phase, 'Scores')
    
    if @assessment.irat?
      @ownerables = @users 
      @ownerable_type = user_class.name
    elsif @assessment.trat?
      @ownerables = @teams
      @ownerable_type = team_class.name
    end

    add_headers_to_sheet(sheet)

    raise AssessmentTypeUndetermined, "Readiness assurance assessment with id #{@assessment.id} has an undetermined type" if @ownerables.nil?

    @ownerables.each_with_index do |ownerable, index|
      process_ownerable(ownerable, index, sheet)
    end
  end

  def process_ownerable(ownerable, index, sheet)
    row_number = index + 1 # Offset by 1 due to header row
    response   = get_response_for_ownerable(ownerable)
    score      = (response.present? && response.score.present?) ? response.score : 'N/A'
    sheet.update_row(row_number, *(caller.get_ownerable_identifiers(ownerable)), score)
  end

  # ### Helpers
  def get_response_for_ownerable(ownerable)
    response = @responses.where(ownerable: ownerable)
    raise MultipleResponses, "Multiple responses found for ownerable with class #{ownerable.class.name} and id #{ownerable.id} for readiness assurance assessment with id #{@assessment.id}" if response.length > 1
    response.first
  end

  class AssessmentTypeUndetermined < StandardError; end
  class MultipleResponses < StandardError; end

  private

  # ### Classes
  def team_class;       Thinkspace::Team::Team;                end
  def user_class;       Thinkspace::Common::User;              end

  # ### Sheet Helpers
  def get_sheet_header_identifiers; caller.get_sheet_header_identifiers(@ownerable_type); end
  def get_sheet_header_score;      'Score';                            end

  def get_headers_for_sheet
    [*(get_sheet_header_identifiers), get_sheet_header_score]
  end 

  def add_headers_to_sheet(sheet)
    headers = get_headers_for_sheet
    caller.add_header_to_sheet(sheet, *headers)
  end   

end; end; end; end

import ember from 'ember'
import ns    from 'totem/ns'
import base  from 'thinkspace-base/components/base'
import ta    from 'totem/ds/associations'
import tc    from 'totem/cache'

###
# # overview.coffee
- Type: **Component**
- Package: **thinkspace-peer-assessment**
###
export default base.extend
  # ## Properties
  # ### Services
  # - **thinkspace-common** 
  #   - [server_events](http://totem-docs.herokuapp.com/api/cellar/thinkspace/client/thinkspace-common/app/services/server_events.html)
  server_events: ember.inject.service()

  #} totem_data_config: ability: true, metadata: {ajax_source: true}  # require metadata so completed count will be updated after a submit

  # ### Internal Properties
  all_phases_completed: null
  is_in_progress:       null
  resume_phase:         null
  team:                 null
  phase_states_loaded:  false

  header_options: ember.computed 'pa_team_set', -> { team_set: @get('pa_team_set') }

  # ### Events
  init_base: ->
    @set_phase_progress()
    @init_assignment_type()
    @init_abilities().then =>
      @init_assessment_phase().then =>
        @init_assessment().then =>
            can_update = @get('model.can.update')
            if can_update
              @init_team_set().then =>
                @init_pubsub()
            else
              @set_team().then =>
                @init_pa_team_set().then =>
                  @init_pubsub()

  # ### Helpers
  set_phase_progress: ->
    assignment = @get('model')
    assignment.get(ns.to_p 'phases' ).then (phases) =>
      phase_promises = phases.getEach(ns.to_p('phase_states'))
      ember.RSVP.Promise.all(phase_promises).then =>
        sorted_phases = phases.sortBy('position')
        resume_phase  = sorted_phases.find (phase) -> phase.get('is_unlocked')
        if resume_phase
          @set 'resume_phase', resume_phase
          @set 'is_in_progress', true  if resume_phase != sorted_phases.get('firstObject')
        uncompleted_phase = phases.find (phase) -> phase.get('is_completed') != true
        @set 'all_phases_completed', true unless uncompleted_phase
        @set 'phase_states_loaded', true
      , (error) =>
        @totem_messages.api_failure error, source: @, model: ns.to_p('phase_states')
    , (error) =>
      @totem_messages.api_failure error, source: @, model: ns.to_p('phases')

  init_assignment_type: ->
    model = @get('model')
    model.get(ta.to_p('assignment_type')).then (assignment_type) =>
      @set('assignment_type', assignment_type)

  init_abilities: ->
    new ember.RSVP.Promise (resolve, reject) =>
      model = @get('model')
      model.totem_data.ability.refresh().then =>
        resolve()

  init_assessment_phase: ->
    model = @get('model')
    model.get(ta.to_p('phases')).then (phases) =>
      return unless ember.isPresent(phases)
      phase = phases.get('firstObject')
      @set('phase', phase)

  init_assessment: ->
    new ember.RSVP.Promise (resolve, reject) =>
      assignment = @get('model')

      query =
        assignment_id: assignment.get('id')
      options =
        action: 'fetch'
        model:  ns.to_p('tbl:assessment')

      @tc.query_action(ns.to_p('assessment'), query, options).then (assessment) =>
        @set 'assessment', assessment.get('firstObject')
        resolve()
      , (error) => reject error

  init_team_set: ->
    new ember.RSVP.Promise (resolve, reject) =>
      phase = @get('phase')
      team_set_id = phase.get('team_set_id')

      @tc.find_record(ta.to_p('team_set'), team_set_id).then (team_set) =>
        @set('team_set', team_set)
        resolve()

  init_pubsub: ->
    assignment = @get('model')
    if assignment.get('is_pubsub')
      @totem_scope.authable(assignment)
      se = @get('server_events')
      se.join_assignment_with_current_user()

  init_pa_team_set: ->
    new ember.RSVP.Promise (resolve, reject) =>
      assessment = @get('assessment')
      query = @totem_scope.get_view_query(assessment, sub_action: 'team_set')['data']
      query.id = query.id || assessment.get('id')
      query.team_id = @get 'team.id'

      options       = @totem_scope.get_view_query(assessment, sub_action: 'team_set')
      options.verb  = 'GET'
      options.model = ta.to_p('tbl:team_set')
      @totem_scope.add_authable_to_query(options)

      @tc.query_action(ta.to_p('tbl:assessment'), query, options).then (team_set) =>
        @set 'pa_team_set', team_set
        resolve(team_set)

  set_team: ->
    new ember.RSVP.Promise (resolve, reject) =>
      query   = @get_sub_action_query_params('teams')
      options = @get_sub_action_query_options('teams', ta.to_p('team'))
      @tc.query_action(ta.to_p('tbl:assessment'), query, options).then (teams) =>
        team = teams.get('firstObject')
        @set 'team', team
        has_team_members = if team.get('users.length') > 1 then true else false
        @set 'has_team_members', has_team_members
        resolve()
      , (error) => 
        @set 'has_team_members', false
        reject() # Send back up to the assessment component so it can set it there, too.
    , (error) => @error(error)

  get_sub_action_query_params: (sub_action) ->
    model = @get('assessment')
    query = @totem_scope.get_view_query(model, sub_action: sub_action)['data']
    query.id = query.id || model.get('id')
    query

  get_sub_action_query_options: (sub_action, model_type) ->
    model         = @get('assessment')
    options       = @totem_scope.get_view_query(model, sub_action: sub_action)
    options.verb  = 'GET'
    options.model = model_type
    @totem_scope.add_authable_to_query(options)
    options


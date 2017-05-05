import ember from 'ember'
import util  from 'totem/util'

export default ember.Object.extend

  ## Model is set to abstract json
  model: null

  abstract: ember.computed.reads 'manager.abstract'
  teams:    ember.computed.reads 'manager.teams'

  last_name:  ember.computed.reads 'model.last_name'
  first_name: ember.computed.reads 'model.first_name'
  team_id:    ember.computed.reads 'model.team_id'

  team: ember.computed 'teams', 'model', ->
    #return null unless ember.isPresent(@get('teams'))
    @get('teams').findBy('id', @get('team_id'))

  computed_title: ember.computed 'teams', 'model', ->
    model = @get('model')
    teams = @get('teams')
    return unless ember.isPresent(model)
    return 'Unassigned' unless ember.isPresent(model.team_id)
    return unless ember.isPresent(teams)
    team = teams.findBy('id', model.team_id)

    if ember.isPresent(team) then return team.title else return 'Unassigned'
import ember          from 'ember'
import ns             from 'totem/ns'
import base_component from 'thinkspace-base/components/base'

export default base_component.extend
  # # Services
  manager: ember.inject.service()

  # # Computed properties
  teams:     ember.computed.reads 'manager.teams'
  team_set:  ember.computed.reads 'manager.team_set'
  abstract:  ember.computed.reads 'manager.abstract'
  has_teams: ember.computed.notEmpty 'teams'

  # # Events
  init_base: -> @set_all_data_loaded()
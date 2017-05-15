import ember from 'ember'
import ns    from 'totem/ns'
import base  from 'thinkspace-common/components/modal/base'

export default base.extend
  # # Properties
  model: null ## Assignment

  # # Computed properties
  date:  ember.computed.reads 'model.release_at'

  actions:
    confirm: (date) -> @sendAction 'select', date
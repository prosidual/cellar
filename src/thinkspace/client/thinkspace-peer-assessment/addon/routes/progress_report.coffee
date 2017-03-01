import ember from 'ember'
import ns    from 'totem/ns'
import base  from 'thinkspace-base/routes/base'

export default base.extend

  titleToken: (model) -> model.get('title') + ' - Progress Report'

  afterModel: (assignment, transition) ->
    @current_models().set_current_models(assignment: assignment).then =>
      @totem_messages.hide_loading_outlet()
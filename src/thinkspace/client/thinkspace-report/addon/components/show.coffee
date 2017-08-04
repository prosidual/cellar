import ember from 'ember'
import ns    from 'totem/ns'
import ajax  from 'totem/ajax'
import base  from 'thinkspace-base/components/base'

export default base.extend

  token: ember.computed.reads 'query_params_controller.token'

  actions:
    back: ->
      @get('model.authable').then (authable) =>
        @get('thinkspace').transition_to_model_route(authable, 'reports')

  init_base: ->
    @set_loading 'all'
    @get_report().then (report) =>
      report.get('authable').then (assignment) =>
        assignment.get('space').then (space) =>
          @reset_loading 'all'

  get_report: ->
    new ember.RSVP.Promise (resolve, reject) =>
      token = @get 'token'
      return unless ember.isPresent(token) # TODO: Raise a totem error?

      query =
        report_token: token

      options =
        action: 'access'
        single: true

      @tc.query_action(ns.to_p('report:report'), query, options).then (report) =>
        @set 'model', report
        resolve(report)

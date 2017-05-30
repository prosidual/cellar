import ember           from 'ember'
import ns              from 'totem/ns'
import tc              from 'totem/cache'
import totem_changeset from 'totem/changeset'
import ta              from 'totem/ds/associations'
import totem_scope     from 'totem/scope'
import step            from './step'
import question_item   from 'thinkspace-builder-rat/items/question'

###
# # content.coffee
- Type: **Step Object**
- Package: **ethinkspace-builder-rat**
###
export default step.extend

  id: 'content'
  index: 1
  route_path: 'content'

  builder: ember.inject.service()
  manager: ember.inject.service()

  model: ember.computed.reads 'builder.model'

  sync_assessments: ember.computed.reads 'model.sync_rat_assessments'
  irat_assessment:  ember.computed.reads 'manager.irat'
  trat_assessment:  ember.computed.reads 'manager.trat'

  cur_irat_question_items: null
  cur_trat_question_items: null

  irat_type: 'irat'
  trat_type: 'trat'

  initialize: ->
    new ember.RSVP.Promise (resolve, reject) =>
      @set_loading('all')
      @create_question_items()

      resolve()

  ## TODO: get this to support trats as well
  create_question_items: (delta=[]) ->
    irat_assessment = @get('irat_assessment')
    questions       = irat_assessment.get('questions_with_answers') || ember.makeArray()

    items = @get('irat_question_items') || ember.makeArray()
    i_ids = items.mapBy('id')
    d_ids = delta.mapBy('id')

    questions.forEach (question) =>
      id = question.id
      i  = questions.indexOf(question)
      if !i_ids.contains(id) || (i_ids.contains(id) && d_ids.contains(id))
        q_item = @create_question_item(@get('irat_type'), question)
        if d_ids.contains(id)
          cur_item = items.filter((item) -> item.get('id') == id).get('firstObject')
          index = items.indexOf(cur_item)
          items.removeAt(index)
          items.insertAt(index, q_item)
        else
          items.pushObject(q_item)

      q_item = items.findBy('id', id)
      q_item.set('changeset.answer', question.answer)
      items.removeObject(q_item)
      items.insertAt(i, q_item)

    q_ids = questions.mapBy('id')
    i_ids = items.mapBy('id')

    del = i_ids.filter ((id) -> !q_ids.contains(id))
    del.forEach (id) => items.removeObject(items.findBy('id', id))

    @set('irat_question_items', items)

  toggle_assessment_sync: (val) ->
    model = @get('model')
    value = model.set_sync_assessment(val)

    model.save().then =>
      @query_assessments().then (assessments) =>
        @set('assessments', assessments)
        @init_assessments()

  # irat_question_items: ember.computed 'irat_assessment.questions_with_answers.length', ->
  #   items     = @get('irat_assessment.questions_with_answers')
  #   cur_items = @get('cur_irat_question_items')
  #   arr       = ember.makeArray()
  #   cur_item_ids = if ember.isPresent(cur_items) then cur_items.mapBy('id') else ember.makeArray()

  #   if ember.isPresent(items)
  #     items.forEach (item) =>
  #       if ember.isPresent(cur_items)
  #         question_obj = cur_items.filter((cur_item) -> cur_item.get('id') == item.id).get('firstObject')

  #       if ember.isPresent(question_obj)
  #         #console.log('question_obj found with item ', item)
  #         #console.log('recomputing irat_question_items with item ', item)
  #         question_obj.set('model', item)
  #         question_obj.set('answer', item.answer)
  #         arr.pushObject(question_obj)
  #       else
  #         arr.pushObject(@create_question_item(@get('irat_type'), item))

  #   @set('cur_irat_question_items', arr)
  #   arr

  # trat_question_items: ember.computed 'trat_assessment.questions_with_answers.@each', ->
  #   items = @get('trat_assessment.questions_with_answers')
  #   if ember.isPresent(items)
  #     @create_question_item(@get('trat_type'), item) for item in items

  create_question_item: (type, item) ->
    question_item.create
      model:      item
      assessment: @get('model')
      type:       type
      ## Container necessary if we want to inject the manager service
      container:  @container

  validate: ->
    new ember.RSVP.Promise (resolve, reject) =>
      irat_items = @get('irat_question_items')
      trat_items = @get('trat_question_items')
      items      = unless @get('sync_assessments') then irat_items.concat(trat_items) else irat_items

      promises = ember.makeArray()

      resolve() unless ember.isPresent(items)
      items.forEach (item) =>
        promises.pushObject(item.validate())

      ember.RSVP.all(promises).then (valids) =>
        resolve(!valids.contains(false))

  save: ->
    new ember.RSVP.Promise (resolve, reject) =>
      @validate().then (validity) =>
        resolve(validity)

  add_question_item: (type) ->
    manager = @get('manager')
    @set_loading('irat')
    manager.add_question_item(type).then =>
      @create_question_items()
      @reset_loading('irat')

  delete_question_item: (type, item_obj) ->
    manager = @get('manager')
    manager.delete_question_item(type, item_obj).then =>
      @create_question_items()

  duplicate_question_item: (type, item_obj) ->
    manager = @get('manager')
    @set_loading('irat')
    manager.duplicate_question_item(type, item_obj).then =>
      @create_question_items()
      @reset_loading('irat')

  reorder_up: (type, item_obj) ->
    manager = @get('manager')
    @set_loading('irat')
    manager.reorder_item(type, item_obj, -1).then =>
      @create_question_items()
      @reset_loading('irat')
    , (error) =>
      @reset_loading('irat')

  reorder_down: (type, item_obj) ->
    manager = @get('manager')
    @set_loading('irat')
    manager.reorder_item(type, item_obj, 1).then =>
      @create_question_items()
      @reset_loading('irat')
    , (error) =>
      @reset_loading('irat')

  reorder_top: (type, item_obj) ->
    manager = @get('manager')
    @set_loading('irat')
    manager.reorder_item(type, item_obj, 'top').then =>
      @reset_loading('irat')
      @create_question_items()

  reorder_bottom: (type, item_obj) ->
    manager = @get('manager')
    @set_loading('irat')
    manager.reorder_item(type, item_obj, 'bottom').then =>
      @reset_loading('irat')
      @create_question_items()
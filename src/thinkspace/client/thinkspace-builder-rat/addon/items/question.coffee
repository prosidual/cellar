import ember             from 'ember'
import util              from 'totem/util'
import totem_changeset   from 'totem/changeset'
import choice_obj        from 'thinkspace-builder-rat/items/question/choice'
import array_helpers     from 'thinkspace-common/mixins/helpers/common/array'
import changeset_helpers from 'thinkspace-common/mixins/helpers/common/changeset'
###
# # question.coffee
# - Type: **Object**
# - Package: **ethinkspace-builder-rat**
###
export default ember.Object.extend array_helpers, changeset_helpers,
  # ### Properties
  model:         null

  manager: ember.inject.service()
  
  id:       ember.computed.reads 'model.id'
  question: ember.computed.reads 'model.question'
  choices:  ember.computed.reads 'model.choices'
  answer:   ember.computed.reads 'model.answer'

  create_choice_item: (item, index) -> choice_obj.create(model: item, index: index, question: @)

  get_choice_by_id: (id)  -> @get('choice_items').findBy 'id', id
  select_answer: (choice) -> @get('changeset').set('answer', choice.get('model.id'))

  init: ->
    @_super()
    console.log('[QUESTION] initing')
    @create_changeset()
    @update_choice_items()


  #######
  ## Changeset Functionality
  #######
  persist: ->
    new ember.RSVP.Promise (resolve, reject) =>
      manager = @get('manager')
      type    = @get('type')
      @validate().then (valid) =>
        if valid
          @changeset_save().then =>
            manager.set_question_answer(type, @get('id'), @get('changeset.answer'))
            resolve(true)
        else
          resolve(false)

  validate: ->
    new ember.RSVP.Promise (resolve, reject) =>
      changesets = ember.makeArray(@get('changeset')).concat(@get('choice_items').mapBy('changeset'))

      @determine_validity(changesets).then (is_valid) =>
        resolve(is_valid)

  changeset_save: ->
    new ember.RSVP.Promise (resolve, reject) =>
      choice_items = @get('choice_items')
      changeset    = @get('changeset')

      promises = ember.makeArray()
      promises.pushObject(changeset.save())
      choice_items.forEach (choice) =>
        promises.pushObject(choice.save())

      ember.RSVP.all(promises).then =>
        resolve()
      , (error) =>
        reject(error)

  changeset_rollback: ->
    new ember.RSVP.Promise (resolve, reject) =>
      choice_items = @get('choice_items')
      changeset    = @get('changeset')

      promises = ember.makeArray()
      promises.pushObject(changeset.rollback())
      choice_items.forEach (choice) =>
        promises.pushObject(choice.rollback())
      ember.RSVP.all(promises).then =>
        @update_choice_items()
        resolve()
      , (error) =>
        reject(error)

  create_changeset: ->
    model     = @get('model')
    vpresence = totem_changeset.vpresence(true)

    choices   = @duplicate_array(@get('model.choices'))
    changeset = totem_changeset.create(model,
      question: [vpresence],
      answer:   [vpresence],
      choices:  [vpresence]
    )

    changeset.set('choices', choices)
    @set('changeset', changeset)

  add_choice_to_item: (type, item_id) ->
    item   = @get('manager').get_item_by_id(type, item_id)
    choice = @get('manager').get_new_choice(item, @get('changeset.choices'))
    @get('changeset.choices').pushObject(choice)
    @update_choice_items()

  delete_choice_from_item: (type, item_id, choice) ->
    item = @get('manager').get_item_by_id(type, item_id)
    @set('changeset.answer', null) if @get('changeset.answer') == choice.id
    @get('changeset.choices').removeObject(choice)
    @update_choice_items()

  update_choice_items: ->
    choice_items = ember.makeArray()
    cur_items    = @get('choice_items')
    items        = @get('changeset.choices')
    answer       = @get('changeset.answer')

    if ember.isPresent(items)
      items.forEach (item, index) =>
        if ember.isPresent(cur_items)
          choice_obj = cur_items.filter((cur_item) -> cur_item.get('id') == item.id).get('firstObject')

        if ember.isPresent(choice_obj)
          choice_obj.set('model', item)
          choice_obj.set('index', index)
          choice_obj.set('question', @)
          choice_items.pushObject(choice_obj)
        else
          choice_items.pushObject(@create_choice_item(item, index))

    @set('choice_items', choice_items)

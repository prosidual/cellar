import buildRoutes from 'ember-engines/routes'

export default buildRoutes ->
  @route 'show',  path: '/:space_id'

import buildRoutes from 'ember-engines/routes'

export default buildRoutes ->
  @route 'configs'
  @route 'locales'
  @route 'tracker'
  @route 'timers'
  @route 'rooms'
  @route 'configs/routes'
  @route 'configs/engines'
  @route 'configs/mounts'
  @route 'locales/show'
  @route 'locales/compare'
  @route 'rooms/users'
  @route 'rooms/counts'

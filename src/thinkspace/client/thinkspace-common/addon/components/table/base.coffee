import ember from 'ember'
import base  from 'thinkspace-base/components/base'

export default base.extend
  # # Helpers
  get_table: -> @get('c_table')
  get_column_data: (property) -> @get("column.data.#{property}")
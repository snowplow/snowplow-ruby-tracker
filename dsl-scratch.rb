
# Define our Tracker
tracker {
  collector :main, cf: 'd1vjp94kduqgnd'
  subject :end_user, ip_address: 'x.x.x.x', business_user_id: 'runkelfinker'
  default_context :end_ctx, platform: :web, app_id: 'shop'
  subject :api_user, business_user_id: Socket.gethostname
  context :api_ctx, platform: :pc, app_id: 'api'
}

# Create the Objects of our events
web_page = Snowplow::WebPage.new(...) # We will use this for Context too
sales_order = Snowplow::SalesOrder.new(...)
struct_event = Snowplow::StructEvent.new(...)
unstruct_event = Snowplow::UnstructEvent.new(...)

# Track some events
track {
  end_user views web_page # Uses default_context
  end_user places sales_order, ~: end_ctx.on(web_page)
  end_user performs struct_event, ~: end_ctx.on(web_page).at(event_tstamp)
  api_user performs unstruct_event, ~: api_ctx
}

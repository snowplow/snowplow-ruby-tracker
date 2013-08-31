collector = Snowplow::Collector(:main, cf: 'd1vjp94kduqgnd')

tracker = Snowplow::Tracker.new(collector)

# Create a couple of Subjects
end_user = Snowplow::Subject.new(ip_address='x.x.x.x', business_user_id='runkelfinker')
api_user = Snowplow::Subject.new(business_user_id='gpfeed')

# Setup Context
ctx = Snowplow::Context.new('web', app_id='shop')

# Track some events
tracker.track do
  end_user views web_page
  end_user places sales_order, ~: ctx.on(web_page)
  end_user performs struct_event, ~: ctx.on(web_page).at(event_tstamp)
  api_user performs unstruct_event, ~: Snowplow::Context.new('pc')
end, ~: ctx

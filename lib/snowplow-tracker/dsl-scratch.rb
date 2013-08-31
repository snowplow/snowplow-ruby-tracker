tracker = SnowplowTracker.new

# Event DSL
tracker.track do
  end_user views web_page ~: ctx
  end_user places sales_order ~: ctx.on(web_page)
  end_user performs struct_event ~: ctx.on(web_page).at(event_tstamp)
end

tracker = SnowplowTracker.new

# returns our aggregated data
tracker.track(ctx) do
  end_user views web_page
  end_user places sales_order
  end_user performs struct_event
end


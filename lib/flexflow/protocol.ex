defprotocol Flexflow.ProcessTracker do
  def ping(o)
end

defprotocol Flexflow.ActivityTracker do
  def ping(o)
end

defprotocol Flexflow.EventTracker do
  def ping(o)
end

defprotocol Flexflow.ProcessTracker do
  def ping(o)
end

defprotocol Flexflow.StateTracker do
  def ping(o)
end

defprotocol Flexflow.EventTracker do
  def ping(o)
end

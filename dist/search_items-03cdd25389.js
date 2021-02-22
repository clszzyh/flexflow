searchNodes=[{"doc":"Usagedefmodule Review do @vsn &quot;1.0.1&quot; use Flexflow.Process defmodule Reviewing do use Flexflow.State end defmodule Submit do use Flexflow.Event end ## Start state state {Start, :draft} state {End, :reviewed} state {End, :canceled} ## Bypass state state :rejected ## Custom state state Reviewing ## Define a event ## `a ~&gt; b` is a shortcut of `{a, b}` event :modify1, :draft ~&gt; :draft event :cancel1, :draft ~&gt; :canceled, results: [:foo] ## Custom event event Submit, :draft ~&gt; Reviewing event :modify2, :rejected ~&gt; :rejected event :cancel2, :rejected ~&gt; :canceled, results: [:foo] ## With custom name event {Submit, :submit2}, :rejected ~&gt; Reviewing event :reject, Reviewing ~&gt; :rejected event :agree, Reviewing ~&gt; :reviewed, results: [:foo] end","ref":"Flexflow.html","title":"Flexflow","type":"module"},{"doc":"See Flexflow.ProcessStatem.call/2.","ref":"Flexflow.html#call/2","title":"Flexflow.call/2","type":"function"},{"doc":"See Flexflow.ProcessStatem.cast/2.","ref":"Flexflow.html#cast/2","title":"Flexflow.cast/2","type":"function"},{"doc":"See Flexflow.History.get/1.","ref":"Flexflow.html#history/1","title":"Flexflow.history/1","type":"function"},{"doc":"See Flexflow.ProcessStatem.pid/1.","ref":"Flexflow.html#pid/1","title":"Flexflow.pid/1","type":"function"},{"doc":"See Flexflow.ProcessManager.server/2.","ref":"Flexflow.html#server/2","title":"Flexflow.server/2","type":"function"},{"doc":"See Flexflow.ProcessManager.start_child/2.","ref":"Flexflow.html#start/2","title":"Flexflow.start/2","type":"function"},{"doc":"See Flexflow.ProcessStatem.state/1.","ref":"Flexflow.html#state/1","title":"Flexflow.state/1","type":"function"},{"doc":"See Flexflow.ProcessManager.stop_child/2.","ref":"Flexflow.html#stop/2","title":"Flexflow.stop/2","type":"function"},{"doc":"","ref":"Flexflow.html#version/0","title":"Flexflow.version/0","type":"function"},{"doc":"","ref":"Flexflow.html#t:id/0","title":"Flexflow.id/0","type":"type"},{"doc":"","ref":"Flexflow.html#t:name/0","title":"Flexflow.name/0","type":"type"},{"doc":"","ref":"Flexflow.html#t:process_args/0","title":"Flexflow.process_args/0","type":"type"},{"doc":"","ref":"Flexflow.html#t:process_identity/0","title":"Flexflow.process_identity/0","type":"type"},{"doc":"","ref":"Flexflow.html#t:process_key/0","title":"Flexflow.process_key/0","type":"type"},{"doc":"","ref":"Flexflow.html#t:state_key/0","title":"Flexflow.state_key/0","type":"type"},{"doc":"","ref":"Flexflow.html#t:state_type/0","title":"Flexflow.state_type/0","type":"type"},{"doc":"","ref":"Flexflow.html#t:state_type_or_module/0","title":"Flexflow.state_type_or_module/0","type":"type"},{"doc":"Default value:telemetry_default_handler: true","ref":"Flexflow.Config.html","title":"Flexflow.Config","type":"module"},{"doc":"","ref":"Flexflow.Config.html#get/1","title":"Flexflow.Config.get/1","type":"function"},{"doc":"","ref":"Flexflow.Config.html#get/2","title":"Flexflow.Config.get/2","type":"function"},{"doc":"Context","ref":"Flexflow.Context.html","title":"Flexflow.Context","type":"module"},{"doc":"","ref":"Flexflow.Context.html#new/0","title":"Flexflow.Context.new/0","type":"function"},{"doc":"","ref":"Flexflow.Context.html#t:t/0","title":"Flexflow.Context.t/0","type":"type"},{"doc":"https://en.wikipedia.org/wiki/DOT_(graph_description_language)https://github.com/TLmaK0/gravizohttps://gravizo.com/http://www.graphviz.org/doc/info/attrs.html","ref":"Flexflow.Dot.html","title":"Flexflow.Dot","type":"module"},{"doc":"","ref":"Flexflow.Dot.html#escape/1","title":"Flexflow.Dot.escape/1","type":"function"},{"doc":"Exampleiex&gt; Elixir.Flexflow.Dot.serialize(Review.new()) &quot;digraph review {\\n size =\\&quot;4,4\\&quot;;\\n draft [label=\\&quot;draft\\&quot;,shape=doublecircle,color=\\&quot;.7 .3 1.0\\&quot;];\\n reviewed [label=\\&quot;reviewed\\&quot;,style=bold,shape=circle,color=red];\\n canceled [label=\\&quot;canceled\\&quot;,shape=circle,color=red];\\n rejected [label=\\&quot;rejected\\&quot;,shape=box];\\n reviewing [label=\\&quot;reviewing\\&quot;,shape=box];\\n draft -&gt; draft [label=\\&quot;modify1\\&quot;];\\n draft -&gt; canceled [label=\\&quot;cancel1\\&quot;];\\n draft -&gt; reviewing [label=\\&quot;submit_draft\\&quot;];\\n rejected -&gt; rejected [label=\\&quot;modify2\\&quot;];\\n rejected -&gt; canceled [label=\\&quot;cancel2\\&quot;];\\n rejected -&gt; reviewing [label=\\&quot;submit2\\&quot;];\\n reviewing -&gt; rejected [label=\\&quot;reject\\&quot;];\\n reviewing -&gt; reviewed [label=\\&quot;agree\\&quot;];\\n}\\n//&quot;","ref":"Flexflow.Dot.html#serialize/1","title":"Flexflow.Dot.serialize/1","type":"function"},{"doc":"","ref":"Flexflow.DotProtocol.html","title":"Flexflow.DotProtocol","type":"protocol"},{"doc":"","ref":"Flexflow.DotProtocol.html#attributes/1","title":"Flexflow.DotProtocol.attributes/1","type":"function"},{"doc":"","ref":"Flexflow.DotProtocol.html#name/1","title":"Flexflow.DotProtocol.name/1","type":"function"},{"doc":"","ref":"Flexflow.DotProtocol.html#prefix/1","title":"Flexflow.DotProtocol.prefix/1","type":"function"},{"doc":"","ref":"Flexflow.DotProtocol.html#suffix/1","title":"Flexflow.DotProtocol.suffix/1","type":"function"},{"doc":"","ref":"Flexflow.DotProtocol.html#t:t/0","title":"Flexflow.DotProtocol.t/0","type":"type"},{"doc":"Event","ref":"Flexflow.Event.html","title":"Flexflow.Event","type":"behaviour"},{"doc":"","ref":"Flexflow.Event.html#c:default_results/0","title":"Flexflow.Event.default_results/0","type":"callback"},{"doc":"","ref":"Flexflow.Event.html#c:graphviz_attribute/0","title":"Flexflow.Event.graphviz_attribute/0","type":"callback"},{"doc":"","ref":"Flexflow.Event.html#c:handle_input/3","title":"Flexflow.Event.handle_input/3","type":"callback"},{"doc":"","ref":"Flexflow.Event.html#c:handle_result/5","title":"Flexflow.Event.handle_result/5","type":"callback"},{"doc":"","ref":"Flexflow.Event.html#init/1","title":"Flexflow.Event.init/1","type":"function"},{"doc":"Invoked after compile, return :ok if valid","ref":"Flexflow.Event.html#c:init/2","title":"Flexflow.Event.init/2","type":"callback"},{"doc":"","ref":"Flexflow.Event.html#c:is_event/1","title":"Flexflow.Event.is_event/1","type":"callback"},{"doc":"","ref":"Flexflow.Event.html#key/1","title":"Flexflow.Event.key/1","type":"function"},{"doc":"Module name","ref":"Flexflow.Event.html#c:name/0","title":"Flexflow.Event.name/0","type":"callback"},{"doc":"","ref":"Flexflow.Event.html#new/3","title":"Flexflow.Event.new/3","type":"function"},{"doc":"","ref":"Flexflow.Event.html#validate/1","title":"Flexflow.Event.validate/1","type":"function"},{"doc":"","ref":"Flexflow.Event.html#c:validate/2","title":"Flexflow.Event.validate/2","type":"callback"},{"doc":"","ref":"Flexflow.Event.html#t:atom_result/0","title":"Flexflow.Event.atom_result/0","type":"type"},{"doc":"","ref":"Flexflow.Event.html#t:event_result/0","title":"Flexflow.Event.event_result/0","type":"type"},{"doc":"","ref":"Flexflow.Event.html#t:key/0","title":"Flexflow.Event.key/0","type":"type"},{"doc":"","ref":"Flexflow.Event.html#t:options/0","title":"Flexflow.Event.options/0","type":"type"},{"doc":"","ref":"Flexflow.Event.html#t:t/0","title":"Flexflow.Event.t/0","type":"type"},{"doc":"EventDispatcher","ref":"Flexflow.EventDispatcher.html","title":"Flexflow.EventDispatcher","type":"module"},{"doc":"Examplesiex&gt; Elixir.Flexflow.EventDispatcher.child_spec([:a, :b, :c]) %{ id: Elixir.Flexflow.EventDispatcher, start: {Registry, :start_link, [[keys: :duplicate, name: Elixir.Flexflow.EventDispatcher]]}, type: :supervisor }","ref":"Flexflow.EventDispatcher.html#child_spec/1","title":"Flexflow.EventDispatcher.child_spec/1","type":"function"},{"doc":"","ref":"Flexflow.EventDispatcher.html#dispatch/1","title":"Flexflow.EventDispatcher.dispatch/1","type":"function"},{"doc":"","ref":"Flexflow.EventDispatcher.html#init_register_all/1","title":"Flexflow.EventDispatcher.init_register_all/1","type":"function"},{"doc":"","ref":"Flexflow.EventDispatcher.html#keys/0","title":"Flexflow.EventDispatcher.keys/0","type":"function"},{"doc":"","ref":"Flexflow.EventDispatcher.html#lookup/1","title":"Flexflow.EventDispatcher.lookup/1","type":"function"},{"doc":"","ref":"Flexflow.EventDispatcher.html#process_register/2","title":"Flexflow.EventDispatcher.process_register/2","type":"function"},{"doc":"","ref":"Flexflow.EventDispatcher.html#register/2","title":"Flexflow.EventDispatcher.register/2","type":"function"},{"doc":"","ref":"Flexflow.EventDispatcher.html#t:entry/0","title":"Flexflow.EventDispatcher.entry/0","type":"type"},{"doc":"","ref":"Flexflow.EventDispatcher.html#t:key/0","title":"Flexflow.EventDispatcher.key/0","type":"type"},{"doc":"","ref":"Flexflow.EventDispatcher.html#t:listen_result/0","title":"Flexflow.EventDispatcher.listen_result/0","type":"type"},{"doc":"","ref":"Flexflow.EventDispatcher.html#t:listener/0","title":"Flexflow.EventDispatcher.listener/0","type":"type"},{"doc":"","ref":"Flexflow.EventTracker.html","title":"Flexflow.EventTracker","type":"protocol"},{"doc":"","ref":"Flexflow.EventTracker.html#ping/1","title":"Flexflow.EventTracker.ping/1","type":"function"},{"doc":"","ref":"Flexflow.EventTracker.html#t:t/0","title":"Flexflow.EventTracker.t/0","type":"type"},{"doc":"Basic","ref":"Flexflow.Events.Basic.html","title":"Flexflow.Events.Basic","type":"module"},{"doc":"Callback implementation for Flexflow.Event.default_results/0.","ref":"Flexflow.Events.Basic.html#default_results/0","title":"Flexflow.Events.Basic.default_results/0","type":"function"},{"doc":"Callback implementation for Flexflow.Event.graphviz_attribute/0.","ref":"Flexflow.Events.Basic.html#graphviz_attribute/0","title":"Flexflow.Events.Basic.graphviz_attribute/0","type":"function"},{"doc":"Callback implementation for Flexflow.Event.handle_input/3.","ref":"Flexflow.Events.Basic.html#handle_input/3","title":"Flexflow.Events.Basic.handle_input/3","type":"function"},{"doc":"Callback implementation for Flexflow.Event.handle_result/5.","ref":"Flexflow.Events.Basic.html#handle_result/5","title":"Flexflow.Events.Basic.handle_result/5","type":"function"},{"doc":"Callback implementation for Flexflow.Event.init/2.","ref":"Flexflow.Events.Basic.html#init/2","title":"Flexflow.Events.Basic.init/2","type":"function"},{"doc":"Callback implementation for Flexflow.Event.is_event/1.","ref":"Flexflow.Events.Basic.html#is_event/1","title":"Flexflow.Events.Basic.is_event/1","type":"function"},{"doc":"Callback implementation for Flexflow.Event.validate/2.","ref":"Flexflow.Events.Basic.html#validate/2","title":"Flexflow.Events.Basic.validate/2","type":"function"},{"doc":"https://erlang.org/doc/man/gen_statem.html#type-state_timeout","ref":"Flexflow.Events.StateTimeout.html","title":"Flexflow.Events.StateTimeout","type":"module"},{"doc":"Callback implementation for Flexflow.Event.graphviz_attribute/0.","ref":"Flexflow.Events.StateTimeout.html#graphviz_attribute/0","title":"Flexflow.Events.StateTimeout.graphviz_attribute/0","type":"function"},{"doc":"Callback implementation for Flexflow.Event.init/2.","ref":"Flexflow.Events.StateTimeout.html#init/2","title":"Flexflow.Events.StateTimeout.init/2","type":"function"},{"doc":"Callback implementation for Flexflow.Event.is_event/1.","ref":"Flexflow.Events.StateTimeout.html#is_event/1","title":"Flexflow.Events.StateTimeout.is_event/1","type":"function"},{"doc":"Callback implementation for Flexflow.Event.validate/2.","ref":"Flexflow.Events.StateTimeout.html#validate/2","title":"Flexflow.Events.StateTimeout.validate/2","type":"function"},{"doc":"History","ref":"Flexflow.History.html","title":"Flexflow.History","type":"module"},{"doc":"Returns a specification to start this module under a supervisor.See Supervisor.","ref":"Flexflow.History.html#child_spec/1","title":"Flexflow.History.child_spec/1","type":"function"},{"doc":"","ref":"Flexflow.History.html#ensure_new/1","title":"Flexflow.History.ensure_new/1","type":"function"},{"doc":"","ref":"Flexflow.History.html#get/1","title":"Flexflow.History.get/1","type":"function"},{"doc":"","ref":"Flexflow.History.html#new/1","title":"Flexflow.History.new/1","type":"function"},{"doc":"","ref":"Flexflow.History.html#put/2","title":"Flexflow.History.put/2","type":"function"},{"doc":"","ref":"Flexflow.History.html#start_link/1","title":"Flexflow.History.start_link/1","type":"function"},{"doc":"","ref":"Flexflow.History.html#t:new_input/0","title":"Flexflow.History.new_input/0","type":"type"},{"doc":"","ref":"Flexflow.History.html#t:stage/0","title":"Flexflow.History.stage/0","type":"type"},{"doc":"","ref":"Flexflow.History.html#t:state/0","title":"Flexflow.History.state/0","type":"type"},{"doc":"","ref":"Flexflow.History.html#t:t/0","title":"Flexflow.History.t/0","type":"type"},{"doc":"Process","ref":"Flexflow.Process.html","title":"Flexflow.Process","type":"behaviour"},{"doc":"","ref":"Flexflow.Process.html#~%3E/2","title":"Flexflow.Process.~>/2","type":"function"},{"doc":"","ref":"Flexflow.Process.html#event/2","title":"Flexflow.Process.event/2","type":"macro"},{"doc":"","ref":"Flexflow.Process.html#event/3","title":"Flexflow.Process.event/3","type":"macro"},{"doc":"","ref":"Flexflow.Process.html#event/4","title":"Flexflow.Process.event/4","type":"macro"},{"doc":"","ref":"Flexflow.Process.html#handle_event/3","title":"Flexflow.Process.handle_event/3","type":"function"},{"doc":"","ref":"Flexflow.Process.html#c:handle_result/2","title":"Flexflow.Process.handle_result/2","type":"callback"},{"doc":"","ref":"Flexflow.Process.html#c:init/1","title":"Flexflow.Process.init/1","type":"callback"},{"doc":"","ref":"Flexflow.Process.html#init/3","title":"Flexflow.Process.init/3","type":"function"},{"doc":"Module name","ref":"Flexflow.Process.html#c:name/0","title":"Flexflow.Process.name/0","type":"callback"},{"doc":"","ref":"Flexflow.Process.html#new/3","title":"Flexflow.Process.new/3","type":"function"},{"doc":"","ref":"Flexflow.Process.html#parse_result/2","title":"Flexflow.Process.parse_result/2","type":"function"},{"doc":"","ref":"Flexflow.Process.html#state/1","title":"Flexflow.Process.state/1","type":"macro"},{"doc":"","ref":"Flexflow.Process.html#state/2","title":"Flexflow.Process.state/2","type":"macro"},{"doc":"","ref":"Flexflow.Process.html#state/3","title":"Flexflow.Process.state/3","type":"macro"},{"doc":"","ref":"Flexflow.Process.html#c:terminate/2","title":"Flexflow.Process.terminate/2","type":"callback"},{"doc":"","ref":"Flexflow.Process.html#t:action/0","title":"Flexflow.Process.action/0","type":"type"},{"doc":"","ref":"Flexflow.Process.html#t:definition/0","title":"Flexflow.Process.definition/0","type":"type"},{"doc":"","ref":"Flexflow.Process.html#t:event_result/0","title":"Flexflow.Process.event_result/0","type":"type"},{"doc":"","ref":"Flexflow.Process.html#t:event_type/0","title":"Flexflow.Process.event_type/0","type":"type"},{"doc":"","ref":"Flexflow.Process.html#t:process_tuple/0","title":"Flexflow.Process.process_tuple/0","type":"type"},{"doc":"Init result","ref":"Flexflow.Process.html#t:result/0","title":"Flexflow.Process.result/0","type":"type"},{"doc":"","ref":"Flexflow.Process.html#t:state_result/0","title":"Flexflow.Process.state_result/0","type":"type"},{"doc":"","ref":"Flexflow.Process.html#t:t/0","title":"Flexflow.Process.t/0","type":"type"},{"doc":"YamlLoader","ref":"Flexflow.ProcessLoader.html","title":"Flexflow.ProcessLoader","type":"module"},{"doc":"ProcessManager","ref":"Flexflow.ProcessManager.html","title":"Flexflow.ProcessManager","type":"module"},{"doc":"","ref":"Flexflow.ProcessManager.html#child_pid/1","title":"Flexflow.ProcessManager.child_pid/1","type":"function"},{"doc":"Returns a specification to start this module under a supervisor.See Supervisor.","ref":"Flexflow.ProcessManager.html#child_spec/1","title":"Flexflow.ProcessManager.child_spec/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#children/1","title":"Flexflow.ProcessManager.children/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#pid/1","title":"Flexflow.ProcessManager.pid/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#server/2","title":"Flexflow.ProcessManager.server/2","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#server_pid/1","title":"Flexflow.ProcessManager.server_pid/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#start_child/2","title":"Flexflow.ProcessManager.start_child/2","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#start_link/1","title":"Flexflow.ProcessManager.start_link/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#stop_child/2","title":"Flexflow.ProcessManager.stop_child/2","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#via_tuple/1","title":"Flexflow.ProcessManager.via_tuple/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessManager.html#t:server_return/0","title":"Flexflow.ProcessManager.server_return/0","type":"type"},{"doc":"","ref":"Flexflow.ProcessManager.html#t:t/0","title":"Flexflow.ProcessManager.t/0","type":"type"},{"doc":"ProcessParentManager","ref":"Flexflow.ProcessParentManager.html","title":"Flexflow.ProcessParentManager","type":"module"},{"doc":"Returns a specification to start this module under a supervisor.See Supervisor.","ref":"Flexflow.ProcessParentManager.html#child_spec/1","title":"Flexflow.ProcessParentManager.child_spec/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessParentManager.html#children/0","title":"Flexflow.ProcessParentManager.children/0","type":"function"},{"doc":"","ref":"Flexflow.ProcessParentManager.html#register/1","title":"Flexflow.ProcessParentManager.register/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessParentManager.html#register_all/0","title":"Flexflow.ProcessParentManager.register_all/0","type":"function"},{"doc":"","ref":"Flexflow.ProcessParentManager.html#start_link/1","title":"Flexflow.ProcessParentManager.start_link/1","type":"function"},{"doc":"Examplesiex&gt; defmodule DemoRegistry do ...&gt; use Elixir.Flexflow.ProcessRegistry ...&gt; end ...&gt; match?({:via, Registry, {Elixir.Flexflow.ProcessRegistry, {DemoRegistry, :abc}}}, DemoRegistry.via_tuple(:abc)) true","ref":"Flexflow.ProcessRegistry.html","title":"Flexflow.ProcessRegistry","type":"module"},{"doc":"Examplesiex&gt; Elixir.Flexflow.ProcessRegistry.child_spec([:a, :b, :c]) %{ id: Elixir.Flexflow.ProcessRegistry, start: {Registry, :start_link, [[keys: :unique, name: Elixir.Flexflow.ProcessRegistry]]}, type: :supervisor }","ref":"Flexflow.ProcessRegistry.html#child_spec/1","title":"Flexflow.ProcessRegistry.child_spec/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessRegistry.html#count/0","title":"Flexflow.ProcessRegistry.count/0","type":"function"},{"doc":"","ref":"Flexflow.ProcessRegistry.html#list/0","title":"Flexflow.ProcessRegistry.list/0","type":"function"},{"doc":"","ref":"Flexflow.ProcessRegistry.html#lookup/1","title":"Flexflow.ProcessRegistry.lookup/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessRegistry.html#pid/1","title":"Flexflow.ProcessRegistry.pid/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessRegistry.html#via_tuple/1","title":"Flexflow.ProcessRegistry.via_tuple/1","type":"function"},{"doc":"gen_statem","ref":"Flexflow.ProcessStatem.html","title":"Flexflow.ProcessStatem","type":"module"},{"doc":"","ref":"Flexflow.ProcessStatem.html#call/2","title":"Flexflow.ProcessStatem.call/2","type":"function"},{"doc":"","ref":"Flexflow.ProcessStatem.html#cast/2","title":"Flexflow.ProcessStatem.cast/2","type":"function"},{"doc":"","ref":"Flexflow.ProcessStatem.html#child_spec/1","title":"Flexflow.ProcessStatem.child_spec/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessStatem.html#handle_result/2","title":"Flexflow.ProcessStatem.handle_result/2","type":"function"},{"doc":"","ref":"Flexflow.ProcessStatem.html#pid/1","title":"Flexflow.ProcessStatem.pid/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessStatem.html#start_link/2","title":"Flexflow.ProcessStatem.start_link/2","type":"function"},{"doc":"","ref":"Flexflow.ProcessStatem.html#state/1","title":"Flexflow.ProcessStatem.state/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessStatem.html#via_tuple/1","title":"Flexflow.ProcessStatem.via_tuple/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessStatem.html#t:handle_event_result/0","title":"Flexflow.ProcessStatem.handle_event_result/0","type":"type"},{"doc":"","ref":"Flexflow.ProcessTracker.html","title":"Flexflow.ProcessTracker","type":"protocol"},{"doc":"","ref":"Flexflow.ProcessTracker.html#ping/1","title":"Flexflow.ProcessTracker.ping/1","type":"function"},{"doc":"","ref":"Flexflow.ProcessTracker.html#t:t/0","title":"Flexflow.ProcessTracker.t/0","type":"type"},{"doc":"See Elixir.Flexflow.Process%Flexflow.Process{actions: [], args: %{}, counter: 0, definitions: [states: :start, states: :end, events: {:start, :end}], listeners: %{}, loop: 0, opts: [], tasks: %{}, vsn: nil, childs: [], context: %{}, events: %{{:start, :end} =&gt; %Flexflow.Event{op: :basic, opts: [], context: %{}, from: :start, module: Flexflow.Events.Basic, name: :first, parentmodule: Flexflow.Events.Basic, results: #MapSet&lt;[:ignore]&gt;, to: :end}}, id: nil, module: Flexflow.Processes.Demo, name: nil, parent: nil, requestid: nil, state: :start, states: %{end: %Flexflow.State{in_edges: [:start], opts: [], out_edges: [], context: %{}, module: Flexflow.States.End, name: :end, type: :end}, start: %Flexflow.State{in_edges: [], opts: [], __out_edges: [:end], context: %{}, module: Flexflow.States.Start, name: :start, type: :start}}}","ref":"Flexflow.Processes.Demo.html","title":"Flexflow.Processes.Demo","type":"module"},{"doc":"","ref":"Flexflow.Processes.Demo.html#new/2","title":"Flexflow.Processes.Demo.new/2","type":"function"},{"doc":"State","ref":"Flexflow.State.html","title":"Flexflow.State","type":"behaviour"},{"doc":"","ref":"Flexflow.State.html#end?/1","title":"Flexflow.State.end?/1","type":"function"},{"doc":"","ref":"Flexflow.State.html#c:graphviz_attribute/0","title":"Flexflow.State.graphviz_attribute/0","type":"callback"},{"doc":"","ref":"Flexflow.State.html#c:handle_enter/2","title":"Flexflow.State.handle_enter/2","type":"callback"},{"doc":"","ref":"Flexflow.State.html#c:handle_event/4","title":"Flexflow.State.handle_event/4","type":"callback"},{"doc":"","ref":"Flexflow.State.html#c:handle_leave/2","title":"Flexflow.State.handle_leave/2","type":"callback"},{"doc":"","ref":"Flexflow.State.html#init/1","title":"Flexflow.State.init/1","type":"function"},{"doc":"","ref":"Flexflow.State.html#c:init/2","title":"Flexflow.State.init/2","type":"callback"},{"doc":"","ref":"Flexflow.State.html#key/1","title":"Flexflow.State.key/1","type":"function"},{"doc":"Module name","ref":"Flexflow.State.html#c:name/0","title":"Flexflow.State.name/0","type":"callback"},{"doc":"","ref":"Flexflow.State.html#new/2","title":"Flexflow.State.new/2","type":"function"},{"doc":"","ref":"Flexflow.State.html#new_name/2","title":"Flexflow.State.new_name/2","type":"function"},{"doc":"","ref":"Flexflow.State.html#normalize_state_key/3","title":"Flexflow.State.normalize_state_key/3","type":"function"},{"doc":"","ref":"Flexflow.State.html#start?/1","title":"Flexflow.State.start?/1","type":"function"},{"doc":"","ref":"Flexflow.State.html#c:type/0","title":"Flexflow.State.type/0","type":"callback"},{"doc":"","ref":"Flexflow.State.html#validate/1","title":"Flexflow.State.validate/1","type":"function"},{"doc":"Invoked after compile, return :ok if valid","ref":"Flexflow.State.html#c:validate/2","title":"Flexflow.State.validate/2","type":"callback"},{"doc":"","ref":"Flexflow.State.html#t:action_result/0","title":"Flexflow.State.action_result/0","type":"type"},{"doc":"","ref":"Flexflow.State.html#t:options/0","title":"Flexflow.State.options/0","type":"type"},{"doc":"","ref":"Flexflow.State.html#t:t/0","title":"Flexflow.State.t/0","type":"type"},{"doc":"","ref":"Flexflow.State.html#t:type/0","title":"Flexflow.State.type/0","type":"type"},{"doc":"","ref":"Flexflow.StateTracker.html","title":"Flexflow.StateTracker","type":"protocol"},{"doc":"","ref":"Flexflow.StateTracker.html#ping/1","title":"Flexflow.StateTracker.ping/1","type":"function"},{"doc":"","ref":"Flexflow.StateTracker.html#t:t/0","title":"Flexflow.StateTracker.t/0","type":"type"},{"doc":"Bypass","ref":"Flexflow.States.Bypass.html","title":"Flexflow.States.Bypass","type":"module"},{"doc":"Callback implementation for Flexflow.State.handle_enter/2.","ref":"Flexflow.States.Bypass.html#handle_enter/2","title":"Flexflow.States.Bypass.handle_enter/2","type":"function"},{"doc":"Callback implementation for Flexflow.State.handle_event/4.","ref":"Flexflow.States.Bypass.html#handle_event/4","title":"Flexflow.States.Bypass.handle_event/4","type":"function"},{"doc":"Callback implementation for Flexflow.State.handle_leave/2.","ref":"Flexflow.States.Bypass.html#handle_leave/2","title":"Flexflow.States.Bypass.handle_leave/2","type":"function"},{"doc":"Callback implementation for Flexflow.State.init/2.","ref":"Flexflow.States.Bypass.html#init/2","title":"Flexflow.States.Bypass.init/2","type":"function"},{"doc":"Callback implementation for Flexflow.State.type/0.","ref":"Flexflow.States.Bypass.html#type/0","title":"Flexflow.States.Bypass.type/0","type":"function"},{"doc":"Callback implementation for Flexflow.State.validate/2.","ref":"Flexflow.States.Bypass.html#validate/2","title":"Flexflow.States.Bypass.validate/2","type":"function"},{"doc":"End","ref":"Flexflow.States.End.html","title":"Flexflow.States.End","type":"module"},{"doc":"Callback implementation for Flexflow.State.handle_enter/2.","ref":"Flexflow.States.End.html#handle_enter/2","title":"Flexflow.States.End.handle_enter/2","type":"function"},{"doc":"Callback implementation for Flexflow.State.handle_event/4.","ref":"Flexflow.States.End.html#handle_event/4","title":"Flexflow.States.End.handle_event/4","type":"function"},{"doc":"Callback implementation for Flexflow.State.handle_leave/2.","ref":"Flexflow.States.End.html#handle_leave/2","title":"Flexflow.States.End.handle_leave/2","type":"function"},{"doc":"Callback implementation for Flexflow.State.init/2.","ref":"Flexflow.States.End.html#init/2","title":"Flexflow.States.End.init/2","type":"function"},{"doc":"Start","ref":"Flexflow.States.Start.html","title":"Flexflow.States.Start","type":"module"},{"doc":"Callback implementation for Flexflow.State.handle_enter/2.","ref":"Flexflow.States.Start.html#handle_enter/2","title":"Flexflow.States.Start.handle_enter/2","type":"function"},{"doc":"Callback implementation for Flexflow.State.handle_event/4.","ref":"Flexflow.States.Start.html#handle_event/4","title":"Flexflow.States.Start.handle_event/4","type":"function"},{"doc":"Callback implementation for Flexflow.State.handle_leave/2.","ref":"Flexflow.States.Start.html#handle_leave/2","title":"Flexflow.States.Start.handle_leave/2","type":"function"},{"doc":"Callback implementation for Flexflow.State.init/2.","ref":"Flexflow.States.Start.html#init/2","title":"Flexflow.States.Start.init/2","type":"function"},{"doc":"Telemetry","ref":"Flexflow.Telemetry.html","title":"Flexflow.Telemetry","type":"module"},{"doc":"","ref":"Flexflow.Telemetry.html#attach_default_handler/0","title":"Flexflow.Telemetry.attach_default_handler/0","type":"function"},{"doc":"","ref":"Flexflow.Telemetry.html#handle_history/4","title":"Flexflow.Telemetry.handle_history/4","type":"function"},{"doc":"","ref":"Flexflow.Telemetry.html#handle_logger/4","title":"Flexflow.Telemetry.handle_logger/4","type":"function"},{"doc":"","ref":"Flexflow.Telemetry.html#handle_state/4","title":"Flexflow.Telemetry.handle_state/4","type":"function"},{"doc":"","ref":"Flexflow.Telemetry.html#invoke_process/3","title":"Flexflow.Telemetry.invoke_process/3","type":"function"},{"doc":"","ref":"Flexflow.Telemetry.html#span/3","title":"Flexflow.Telemetry.span/3","type":"function"},{"doc":"","ref":"Flexflow.Telemetry.html#t:state_type/0","title":"Flexflow.Telemetry.state_type/0","type":"type"},{"doc":"Optionsenable_process_history Enable Process history in :etstelemetry_logger Enable default logger handler, default falsetelemetry_logger_level Logger level, default debug","ref":"Flexflow.Telemetry.html#t:t/0","title":"Flexflow.Telemetry.t/0","type":"type"},{"doc":"Flexflow","ref":"readme.html","title":"Flexflow","type":"extras"},{"doc":"defmodule Review do @vsn &quot;1.0.1&quot; use Flexflow.Process defmodule Reviewing do use Flexflow.State end defmodule Submit do use Flexflow.Event end ## Start state state {Start, :draft} state {End, :reviewed} state {End, :canceled} ## Bypass state state :rejected ## Custom state state Reviewing ## Define a event ## `a ~&gt; b` is a shortcut of `{a, b}` event :modify1, :draft ~&gt; :draft event :cancel1, :draft ~&gt; :canceled, results: [:foo] ## Custom event event Submit, :draft ~&gt; Reviewing event :modify2, :rejected ~&gt; :rejected event :cancel2, :rejected ~&gt; :canceled, results: [:foo] ## With custom name event {Submit, :submit2}, :rejected ~&gt; Reviewing event :reject, Reviewing ~&gt; :rejected event :agree, Reviewing ~&gt; :reviewed, results: [:foo] end","ref":"readme.html#usage","title":"Flexflow - Usage","type":"extras"},{"doc":"&lt;summary&gt;&lt;img src=&quot;https://g.gravizo.com/source/review_mark?https%3A%2F%2Fraw.githubusercontent.com%2Fclszzyh%2Fflexflow%2Fmaster%2FREADME.md&quot;&gt;&lt;/summary&gt;```dot// review_markdigraph review { size =&quot;4,4&quot;; draft [label=&quot;draft&quot;,shape=doublecircle,color=&quot;.7 .3 1.0&quot;]; reviewed [label=&quot;reviewed&quot;,style=bold,shape=circle,color=red]; canceled [label=&quot;canceled&quot;,shape=circle,color=red]; rejected [label=&quot;rejected&quot;,shape=box]; reviewing [label=&quot;reviewing&quot;,shape=box]; draft -&gt; draft [label=&quot;modify1&quot;]; draft -&gt; canceled [label=&quot;cancel1&quot;]; draft -&gt; reviewing [label=&quot;submit_draft&quot;]; rejected -&gt; rejected [label=&quot;modify2&quot;]; rejected -&gt; canceled [label=&quot;cancel2&quot;]; rejected -&gt; reviewing [label=&quot;submit2&quot;]; reviewing -&gt; rejected [label=&quot;reject&quot;]; reviewing -&gt; reviewed [label=&quot;agree&quot;];}// review_mark```","ref":"readme.html#graphviz-dot","title":"Flexflow - Graphviz Dot","type":"extras"},{"doc":"Support :gen_statemState(S) x Event(E) -&gt; Actions(A), State(S&#39;)","ref":"readme.html#todo","title":"Flexflow - TODO","type":"extras"},{"doc":"https://erlang.org/doc/design_principles/statem.htmlhttps://en.wikipedia.org/wiki/Business_Process_Model_and_Notation","ref":"readme.html#see-also","title":"Flexflow - See also","type":"extras"},{"doc":"Changelog","ref":"changelog.html","title":"Changelog","type":"extras"},{"doc":"Full Changelog","ref":"changelog.html#v0-2-0-2021-02-22","title":"Changelog - v0.2.0 (2021-02-22)","type":"extras"},{"doc":"Full ChangelogClosed issues:[CI FAIL] fix ci [Fixed by fix ci] #37[CI FAIL] state_timeout [Fixed by fix ci] #36[CI FAIL] fix test [Fixed by fix ci] #35[CI FAIL] remove exist [Fixed by fix ci] #34[CI FAIL] fix dialyzer [Fixed by fix ci] #33[CI FAIL] unique [Fixed by fix ci] #31[CI FAIL] dynamic module [Fixed by fix ci] #28[CI FAIL] fix ci [Fixed by Revert &quot;fix ci&quot;] #27[CI FAIL] fix ci [Fixed by Revert &quot;fix ci&quot;] #26[CI FAIL] fix ci [Fixed by Revert &quot;fix ci&quot;] #25[CI FAIL] rerun ci [Fixed by Revert &quot;fix ci&quot;] #24[CI FAIL] [ci] fix dialyzer [Fixed by Revert &quot;fix ci&quot;] #23[CI FAIL] alias [Fixed by Revert &quot;fix ci&quot;] #22[CI FAIL] mark [Fixed by mark] #20[CI FAIL] refactor [Fixed by test] #19[CI FAIL] ; [Fixed by test] #18Merged pull requests:Bump dialyxir from 1.0.0 to 1.1.0 #32 (dependabot[bot])Bump credo from 1.5.4 to 1.5.5 #30 (dependabot[bot])dependabot: bump actions/cache from v2 to v2.1.4 #29 (dependabot[bot])dependabot: bump charmixer/auto-changelog-action from v1.1 to v1.2 #21 (dependabot[bot])","ref":"changelog.html#v0-1-9-2021-02-22","title":"Changelog - v0.1.9 (2021-02-22)","type":"extras"},{"doc":"Full ChangelogClosed issues:[CI FAIL] history add time [Fixed by history add time] #17[CI FAIL] vsn [Fixed by fix test] #16[CI FAIL] check exist [Fixed by check exist] #15","ref":"changelog.html#v0-1-8-2021-01-26","title":"Changelog - v0.1.8 (2021-01-26)","type":"extras"},{"doc":"Full ChangelogClosed issues:[CI FAIL] test [Fixed by refactor] #14[CI FAIL] async [Fixed by async] #13[CI FAIL] update readme [Fixed by fix test] #12","ref":"changelog.html#v0-1-7-2021-01-24","title":"Changelog - v0.1.7 (2021-01-24)","type":"extras"},{"doc":"Full ChangelogClosed issues:[CI FAIL] fix test [Fixed by test] #11[CI FAIL] dispatch [Fixed by test] #10[CI FAIL] rename [Fixed by rename] #9[CI FAIL] start [Fixed by continue] #8[CI FAIL] process [Fixed by Api] #7","ref":"changelog.html#v0-1-6-2021-01-22","title":"Changelog - v0.1.6 (2021-01-22)","type":"extras"},{"doc":"Full Changelog","ref":"changelog.html#v0-1-5-2021-01-21","title":"Changelog - v0.1.5 (2021-01-21)","type":"extras"},{"doc":"Full Changelog","ref":"changelog.html#v0-1-4-2021-01-20","title":"Changelog - v0.1.4 (2021-01-20)","type":"extras"},{"doc":"Full ChangelogClosed issues:[CI FAIL] server [Fixed by server] #4","ref":"changelog.html#v0-1-3-2021-01-18","title":"Changelog - v0.1.3 (2021-01-18)","type":"extras"},{"doc":"Full Changelog","ref":"changelog.html#v0-1-2-2021-01-17","title":"Changelog - v0.1.2 (2021-01-17)","type":"extras"},{"doc":"Full Changelog","ref":"changelog.html#v0-1-1-2021-01-17","title":"Changelog - v0.1.1 (2021-01-17)","type":"extras"},{"doc":"Full ChangelogClosed issues:[CI FAIL] ci [Fixed by ci] #3[CI FAIL] register [Fixed by ci] #2* This Changelog was automatically generated by github_changelog_generator","ref":"changelog.html#v0-1-0-2021-01-16","title":"Changelog - v0.1.0 (2021-01-16)","type":"extras"}]
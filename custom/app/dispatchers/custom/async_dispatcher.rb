# Picked up by the existing AsyncDispatcher.prepend_mod_with('AsyncDispatcher')
# call (app/dispatchers/async_dispatcher.rb) -- zero core edits required.
module Custom::AsyncDispatcher
  def listeners
    super + [CoopCoreListener.instance]
  end
end

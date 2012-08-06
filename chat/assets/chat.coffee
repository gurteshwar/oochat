class window.Chat
  constructor: (@messageHub, @collapseTimeWindow, @channelControls, @dateTimeHelper, @username, @sound) ->
    @init()

  init: ->
    @messageContainerTemplate = $("#message-container-template").html()
    @messagePartialTemplate = $("#message-partial-template").html()
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-preview").click(@onPreviewSubmit)
    $(".chat-edit").click(@onEditSubmit)
    $(".chat-text").bind("keydown.return", @onChatSubmit)
    $(".chat-text").bind("keydown.meta_return", @onChatSubmit)
    @messageHub.on("publish_message", @onNewMessage)
    @messageHub.on("preview_message", @onPreviewMessage)

  onPreviewSubmit: (event) =>
    message = $(".chat-text").val()
    if message.replace(/\s*$/, "") isnt ""
      @messageHub.sendPreview(message, @channelControls.currentChannel)

    previewContainer = $(".preview-wrapper")
    previewButton = $(".chat-preview")
    editButton = $(".chat-edit")
    chatTextContainer = $(".chat-text-wrapper")
    previewButton.hide()
    editButton.show()
    chatTextContainer.hide()
    previewContainer.show()

  onEditSubmit: (event) =>
    previewContainer = $(".preview-wrapper")
    previewButton = $(".chat-preview")
    editButton = $(".chat-edit")
    chatTextContainer = $(".chat-text-wrapper")
    previewButton.show()
    editButton.hide()
    chatTextContainer.show()
    previewContainer.hide()

  onChatSubmit: (event) =>
    if event.type == "click" || $.cookie("autoSend") == "true" || ($.cookie("autoSend") == "false" && event.metaKey)
      message = $(".chat-text").val()
      if message.replace(/\s*$/, "") isnt ""
        @messageHub.sendChat(message, @channelControls.currentChannel)
      $(".chat-text").val("").focus()
      event.preventDefault()

  checkAndNotify: (message) =>
    if message.find(".its-you").length > 0 and (!document.hasFocus() or document.webkitHidden)
      @sound.playNewMessageAudio()

  onNewMessage: (event, messageObject) =>
    bottom = Util.scrolledToBottom()
    messagePartial = @renderMessagePartial(messageObject)
    @checkAndNotify(messagePartial)
    @appendMessage(messageObject, messagePartial)
    Util.scrollToBottom("animate") if bottom

  onPreviewMessage: (event, messageObject) =>
    messagePreviewDiv = $(".preview-wrapper .message")
    $messageContainer = $(Mustache.render(@messagePartialTemplate, messageObject))
    messagePreviewDiv.replaceWith($messageContainer)

  appendInitialMessages: (messageDict) =>
    for channel, messages of messageDict
      for message in messages
        messagePartial = @renderMessagePartial(message)
        @appendMessage(message, messagePartial)

  # following three functions are helpers for @appendMessage
  findMessageEmail: (message) -> message.find(".email").text()
  findMessageTime: (message) -> parseInt(message.find(".time").attr("data-time"))
  newMessageInTimeWindow: (recentMessage, oldMessage) =>
    # recentMessage: a javascript object (received from the server socket connection)
    # oldMessage: a JQuery object (from the DOM)
    (recentMessage["datetime"] - @findMessageTime(oldMessage)) <= @collapseTimeWindow

  renderMessagePartial: (message) =>
    mustached = $(Mustache.render(@messagePartialTemplate, message))
    mustached.find(".user-mention[data-username='#{@username}']").addClass("its-you")
    mustached

  appendMessage: (message, messagePartial) =>
    messagesList = $(".chat-messages-container[data-channel='#{message["channel"]}']")
    lastMessage = messagesList.find(".message-container").last()

    # if the author of consecutive messages are the same, collapse them
    if @findMessageEmail(lastMessage) is message["email"] and @newMessageInTimeWindow(message, lastMessage)
      messagePartial.appendTo(lastMessage)
      # remove the old time data binding and refresh the time attribute
      timeContainer = lastMessage.find(".time")
      timeContainer.attr("data-time", message["datetime"])
      @dateTimeHelper.removeBindings(timeContainer)
    else
      $messageContainer = $(Mustache.render(@messageContainerTemplate, message))
      $messageContainer.filter(".message-container").append(messagePartial)
      $messageContainer.appendTo(messagesList)
      timeContainer = $messageContainer.find(".time")
    @dateTimeHelper.bindOne(timeContainer)
    @dateTimeHelper.updateTimestamp(timeContainer)

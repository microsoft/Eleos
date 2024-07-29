const ChatBubble = ({ msg }) => {
    return (
        <div className={`bubble ${msg.participant === 'bot' ? 'bot' : 'user'}`}>
            {msg.value}
        </div>
    );
};

export default ChatBubble;

import {useState, useEffect, useRef} from 'react';
import axios from 'axios';
import ChatBubble from './ChatBubble.tsx';
import MessageLoader from './MessageLoader.tsx';
import './Chat.css';
import chatLogo from '../../assets/chat-logo.svg';

const Chat = ({context, user}) => {
    const [messages, setMessages] = useState([{participant: 'bot', value: "Hello, I'm APIM Bot!"}]);
    const [query, setQuery] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const formBoxRef = useRef(null);
    const chatBoxRef = useRef(null);
    const chatInputRef = useRef(null);

    const submit = async () => {
        if (query) {
            const newMessage = {participant: user, value: query};
            setMessages(prevMessages => [...prevMessages, newMessage]);
            setIsLoading(true);

            try {
                const response = await axios.post('/ChatService/message', {
                    query: query,
                    context: {...context, chat: messages}
                });
                setMessages(prevMessages => [...prevMessages, {participant: 'bot', value: response.data.response}]);
                setIsLoading(false);
            } catch (error) {
                setTimeout(() => {
                    setIsLoading(false);
                    setMessages(prevMessages => [...prevMessages, {
                        participant: 'bot',
                        value: `I'm sorry. It seems like I'm having difficulties right now. Please try again later.`
                    }]);
                }, 1000);
            } finally {
                setQuery('');
                setIsLoading(true);
            }
        }
    };

    useEffect(() => {
        if (chatBoxRef.current) {
            chatBoxRef.current.scrollTop = chatBoxRef.current.scrollHeight;
        }
    }, [messages, isLoading]);

    return (
        <>
            <button className={`floating-btn ${isOpen ? 'clicked' : ''}`} onClick={() => setIsOpen(!isOpen)}>
                <img className="chat-logo" src={chatLogo} alt="Ask a Question"/>
            </button>
            <div className={`form-box ${isOpen ? 'open' : ''}`} ref={formBoxRef}>
                <h2 className="login-header"><i className="far fa-comment-dots icon"></i>What's your question?</h2>
                <div className="chat" ref={chatBoxRef}>
                    <div className="legal">
                        AI chats may not always provide accurate or up-to-date information. It is important to consult a
                        licensed healthcare professional for accurate and personalized medical advice.
                    </div>
                    {messages.map((msg, index) => (
                        <ChatBubble key={index} msg={msg}/>
                    ))}
                    {isLoading && <MessageLoader/>}
                </div>
                <div className="message-box">
                    <input
                        ref={chatInputRef}
                        value={query}
                        onChange={(e) => setQuery(e.target.value)}
                        onKeyUp={(e) => e.key === 'Enter' && submit()}
                        type="text"
                        className="message-input"
                        placeholder="Type your question..."
                    />
                    <button onClick={submit} className="message-submit">Send</button>
                </div>
            </div>
        </>
    );
};

export default Chat;

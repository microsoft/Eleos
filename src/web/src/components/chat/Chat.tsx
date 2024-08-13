import { useState, useEffect, useRef, FormEvent } from 'react';
import axios from 'axios';
import ChatBubble from './ChatBubble.tsx';
import MessageLoader from './MessageLoader.tsx';
import './Chat.css';
import chatLogo from '../../assets/chat-logo.svg';
// @ts-expect-error cheating more...
import { v4 as uuidv4 } from 'uuid';

interface ChatMessage {
    participant: string;
    value: {
        text: string;
    }
}

// @ts-expect-error this is a port from a project without as strong linting.. this will be fixed for compile but works fine at runtime
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const Chat = ({ context, user }) => {
    const [userId, setUerId] = useState<string | null>(null);
    const [session] = useState(uuidv4());
    const [messages, setMessages] = useState<ChatMessage[]>([]);
    const [query, setQuery] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const formBoxRef = useRef(null);
    const chatBoxRef = useRef(null);
    const chatInputRef = useRef(null);

    const submit = async () => {
        if (query) {
            const newMessage = { participant: user, value: { text: query } } as ChatMessage;

            setMessages(prevMessages => [...prevMessages, newMessage]);
            setIsLoading(true);
            setQuery('');

            try {
                let url = `${import.meta.env.VITE_FUNC_HOST}/api/chat-post`;
                if (import.meta.env.VITE_IS_DEPLOYED === 'true')
                    url += `?code=${import.meta.env.VITE_FUNC_CODE}`;
                const response = await axios.post(url, {
                    session_id: session,
                    user_id: userId,
                    messages: query
                });
                setMessages(prevMessages => [...prevMessages, { participant: 'bot', value: response.data }]);
            } catch (error) {
                console.error(error);
                setTimeout(() => {
                    setIsLoading(false);
                    setMessages(prevMessages => [...prevMessages, {
                        participant: 'bot',
                        value: { text: `I'm sorry. It seems like I'm having difficulties right now. Please try again later.` }
                    }]);
                }, 1000);
            } finally {
                setIsLoading(false);
            }
        }
    };

    useEffect(() => {
        if (chatBoxRef.current) {
            // @ts-expect-error this is a port from a project without as strong linting.. this will be fixed for compile but works fine at runtime
            chatBoxRef.current.scrollTop = chatBoxRef.current.scrollHeight;
        }
    }, [messages, isLoading]);

    const handleLogin = (e: FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        const userId = new FormData(e.target as HTMLFormElement).get('username')?.toString()
        setUerId(userId || null);
        setMessages([...messages, { participant: 'bot', value: { text: `Hello ${userId}, I'm APIM Bot!` } }]);

    };

    return (
        <>
            <button className={`floating-btn ${isOpen ? 'clicked' : ''}`} onClick={() => setIsOpen(!isOpen)}>
                <img className="chat-logo" src={chatLogo} alt="Ask a Question" />
            </button>
            <div className={`form-box ${isOpen ? 'open' : ''}`} ref={formBoxRef}>
                <h2 className="login-header"><i className="far fa-comment-dots icon"></i>What's your question?</h2>
                {
                    userId == null &&
                    <>
                        <form onSubmit={handleLogin} className="login-form">
                            <div className="form-group">
                                <input
                                    placeholder="Name"
                                    name="username"
                                    type="text"
                                    required
                                    className="form-input"
                                />
                                <button type="submit" className="form-button">Login</button>
                            </div>
                        </form>
                    </>
                }
                {
                    userId !== null &&
                    <>
                        <div className="chat" ref={chatBoxRef}>
                            <div className="legal">
                                AI chats may not always provide accurate or up-to-date information.
                            </div>
                            {messages.map((msg, index) => (
                                <ChatBubble key={index} msg={msg} />
                            ))}
                            {isLoading && <MessageLoader />}
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
                    </>
                }

            </div>
        </>
    );
};

export default Chat;

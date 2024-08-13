import {useEffect, useState} from 'react';

// @ts-expect-error this is a port from a project without as strong linting.. this will be fixed for compile but works fine at runtime
const ChatBubble = ({ msg }) => {
    const [currentRoute, setCurrentRoute] = useState(window.location.hash.replace('#', '') || '/');
    
    useEffect(() => {
        const onHashChange = () => {
            setCurrentRoute(window.location.hash.replace('#', ''));
        };

        window.addEventListener('hashchange', onHashChange);

        return () => {
            window.removeEventListener('hashchange', onHashChange);
        };
    }, []);

    const navigate = (path: string): void => {
        console.log('changing current route from', currentRoute);
        window.location.hash = path;
        setCurrentRoute(path);
    };

    return (
        <>
            <div className={`bubble ${msg.participant === 'bot' ? 'bot' : 'user'}`}>
                {msg.value.text && <div>{msg.value.text}</div>}
                {msg.value.summary && <div className="text-element">{msg.value.summary}</div>}
                {msg.value.description && <div className="text-element">{msg.value.description}</div>}
                {msg.value.portal_url && <a className="action" href={msg.value.portal_url} onClick={(e) => { e.preventDefault(); navigate('' + msg.value.portal_url); }}>Click to view API</a>}
                {!msg.value.text && !msg.value.summary && !msg.value.description && !msg.value.portal_url && <div>{msg.value}</div>}
        </div>
        </>
    );
};

export default ChatBubble;

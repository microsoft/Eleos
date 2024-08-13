import { FC } from 'react';
import './App.css';
import { initializeIcons } from '@fluentui/react/lib/Icons';
import logo from './logo.svg';
import Chat from "./components/chat/Chat.tsx";

initializeIcons(undefined, { disableWarnings: true });

const App: FC = () => {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
      {/* @ts-expect-error this is a port from a project without as strong linting.. this will be fixed for compile but works fine at runtime */}
      <Chat></Chat>
    </div>
  );
};

export default App;

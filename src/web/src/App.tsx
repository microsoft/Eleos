import { FC } from 'react';
// import { useReducer, FC } from 'react';
// import { BrowserRouter } from 'react-router-dom';
// import Layout from './layout/layout';
import './App.css';
import { DarkTheme } from './ux/theme';
// import { AppContext, ApplicationState, getDefaultState } from './models/applicationState';
// import appReducer from './reducers';
// import { TodoContext } from './components/todoContext';
import { initializeIcons } from '@fluentui/react/lib/Icons';
import { ThemeProvider } from '@fluentui/react';
// import Telemetry from './components/telemetry';
import logo from './logo.svg';
import Chat from "./components/chat/Chat.tsx";

initializeIcons(undefined, { disableWarnings: true });

const App: FC = () => {
  // const defaultState: ApplicationState = getDefaultState();
  // const [applicationState, dispatch] = useReducer(appReducer, defaultState);
  // const initialContext: AppContext = { state: applicationState, dispatch: dispatch }

  return (
    <ThemeProvider applyTo="body" theme={DarkTheme}>
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

      {/* <TodoContext.Provider value={initialContext}>
        <BrowserRouter>
          <Telemetry>
            <Layout />
          </Telemetry>
        </BrowserRouter>
      </TodoContext.Provider> */}
    </ThemeProvider>
  );
};

export default App;

import { Elm } from './Notes.elm';

const app = Elm.Notes.init({ node: document.getElementById('root') });
const mainWindow = window.opener;

app.ports.nextSlide &&
  app.ports.nextSlide.subscribe(() => {
    mainWindow.postMessage('nextSlide', 'localhost:8000');
  });

app.ports.previousSlide &&
  app.ports.previousSlide.subscribe(() => {
    mainWindow.postMessage('previousSlide', 'localhost:8000');
  });

window.addEventListener('message', (e) => {
  if (e.source === 'localhost:8000') {
    app.ports.messageFromMain.send(e.data);
  }
});

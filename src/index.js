import { Elm } from './Main.elm';

const app = Elm.Main.init({ node: document.getElementById('root') });
let notesWindow = null;

app.ports.openNotes &&
  app.ports.openNotes.subscribe(() => {
    if (notesWindow == null) {
      notesWindow = window.open('localhost:3000', '_blank');
    }
  });

app.ports.closeNotes &&
  app.ports.closeNotes.subscribe(() => {
    if (notesWindow != null) {
      notesWindow.close();
    }
  });

window.addEventListener('message', (e) => {
  if (e.source === 'localhost:3000') {
    app.ports.messageFromNotes.send(e.data);
  }
});

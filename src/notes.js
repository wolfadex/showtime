import { ipcRenderer } from 'electron';
import { Elm } from './Notes.elm';

const app = Elm.Notes.init({ node: document.getElementById('root') });

app.ports.nextSlide &&
  app.ports.nextSlide.subscribe(() => {
    ipcRenderer.send('nextSlide');
  });

app.ports.previousSlide &&
  app.ports.previousSlide.subscribe(() => {
    ipcRenderer.send('previousSlide');
  });

ipcRenderer.on('updateNotes', (e, notes) => {
  app.ports.updateNotes && app.ports.updateNotes.send(notes);
});

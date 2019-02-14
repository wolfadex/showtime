import { ipcRenderer } from 'electron';
import { Elm } from './Main.elm';

const app = Elm.Main.init({ node: document.getElementById('root') });

app.ports.openNotes &&
  app.ports.openNotes.subscribe(() => {
    ipcRenderer.send('openNotes');
  });

app.ports.closeNotes &&
  app.ports.closeNotes.subscribe(() => {
    ipcRenderer.send('closeNotes');
  });

app.ports.updateNotes &&
  app.ports.updateNotes.subscribe((notes) => {
    ipcRenderer.send('updateNotes', notes);
  });

ipcRenderer.on('nextSlide', () => {
  app.ports.nextSlide && app.ports.nextSlide.send('');
});

ipcRenderer.on('previousSlide', () => {
  app.ports.previousSlide && app.ports.previousSlide.send('');
});

const {
  addNoteHandler,
  getAllNotesHandler,
  getNoteByIdHandler,
  editNoteByIdHandler,
  deleteNoteByIdHandler,
} = require('./handler')

const routes = [
  {
    method: 'POST',
    path: '/notes',
    handler: () => {},
  },
]

module.exports = routes
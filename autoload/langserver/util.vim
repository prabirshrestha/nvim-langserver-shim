
let s:diagnostic_severity = {
      \ 'Error': 1,
      \ 'Warning': 2,
      \ 'Informatin': 3,
      \ 'Hint': 4,
      \ }


" Basic Json Structures
"

""
" Get a uri from a filename
function! langserver#util#get_uri(name, filename) abort
  if has('win32') || has('win64')
    return 'file:///' . substitute(a:filename, '\', '/', 'g')
  else
    return 'file://' . a:filename
  endif
endfunction

""
" Get a filename from a uri
function! langserver#util#get_filename(name, uri) abort
  return substitute(a:uri, 'file://', '', 'g')
endfunction

""
" Get the root path
" TODO: Not sure how to do this one well
function! langserver#util#get_root_path(name) abort
  return langserver#util#get_uri(a:name, getcwd())
endfunction

""
" Get a position dictinoary like the position structure
"
" Follows spec: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#position
function! langserver#util#get_position() abort
  return {'line': line('.') - 1, 'character': col('.') - 1}
endfunction

""
" A range in a text document expressed as (zero-based) start and end positions.
" A range is comparable to a selection in an editor. Therefore the end position is exclusive.
"
" Follows spec: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#range
function! langserver#util#get_range(start, end) abort
  " TODO: Make sure that these are the correct relativeness,
  return {'start': a:start, 'end': a:end}
endfunction

""
" Represents a location inside a resource, such as a line inside a text file.
"
" Follows spec: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#location
function! langserver#util#get_location(start, end) abort
  return {
        \ 'uri': expand('%'),
        \ 'range': langserver#util#get_range(a:start, a:end)
        \ }
endfunction

""
" Represents a diagnostic, such as a compiler error or warning. Diagnostic objects are only valid in the scope of a resource.
"
" Follows spec: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#diagnostic
"
" @param start (int)
" @param end (int)
" @param message (str)
" @param options (dict): Contiainings items like:
"   @key severity (string): Matching key to s:diagnostic_severity
"   @key code TODO
"   @key source TODO
function! langserver#util#get_diagnostic(start, end, message, options) abort
  let l:return_dict = {
        \ 'range': langserver#util#get_range(a:start, a:end),
        \ 'messsage': a:message
        \ }

  if has_key(a:options, 'severity')
    let l:return_dict['severity'] = a:options['severity']
  endif

  if has_key(a:options, 'code')
    let l:return_dict['code'] = a:options['code']
  endif

  if has_key(a:options, 'source')
    let l:return_dict['source'] = a:options['source']
  endif

  return l:return_dict
endfunction

""
" Represents a reference to a command.
" Provides a title which will be used to represent a command in the UI.
" Commands are identitifed using a string identifier and the protocol currently doesn't specify a set of well known commands.
" So executing a command requires some tool extension code.
"
" Corresponds to: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#command
"
" @param title (str): Title of the command
" @param command (str): The identifier of the actual command handler
" @param arguments (Optional[list]): Optional list of arguments passed to the command
function! langserver#util#get_command(title, command, ...) abort
  let l:return_dict = {
        \ 'title': a:title,
        \ 'command': a:command,
        \ }

  if a:0 > 1
    let l:return_dict['arguments'] = a:1
  endif
endfunction

""
" A textual edit applicable to a text document.
"
" Corresponds to: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#textedit
"
" @param start (int)
" @param end (int)
" @param new_text (string): The string to be inserted. Use an empty string for
" delete
function! langserver#util#get_text_edit(start, end, new_text) abort
  return {
        \ 'range': langserver#util#get_range(a:start, a:end),
        \ 'newText': a:new_text
        \ }
endfunction

""
" A workspace edit represents changes to many resources managed in the workspace.
"
" Corresponds to: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#workspaceedit
"
" TODO: Figure out a better way to do this.
" @param
function! langserver#util#get_workspace_edit(uri, edit) abort
  let l:my_dict = {
        \ 'uri': 'edit',
        \ }
endfunction

""
" Text documents are identified using a URI. On the protocol level, URIs are passed as strings. The corresponding JSON structure looks like this:
"
" Corresponds to: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#textdocumentidentifier
function! langserver#util#get_text_document_identifier(name) abort
  " TODO: I'm not sure if I'll be looking to get other items or what from this
  " function
  return {'uri': langserver#util#get_uri(a:name, expand('%:p'))}
  " return {'uri': langserver#util#get_uri(a:name, expand('%'))}
endfunction

""
" New: An identifier to denote a specific version of a text document.
"
" @param version (Optional[int]): If specified, refer to this version
function! langserver#util#get_versioned_text_document_identifier(...) abort
  let l:return_dict = langserver#util#get_text_document_identifier()

  if a:0 > 0
    let l:version = a:1
  else
    " Add the version number to the text document identifier
    " And don't increment the count for the version
    let l:version = langserver#version#get_version(l:return_dict['uri'], v:false)
  endif

  call extend(l:return_dict, {'version': l:version})

  return l:return_dict
endfunction

""
" An item to transfer a text document from the client to the server.
"
" Corresponds to: https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#textdocumentitem
function! langserver#util#get_text_document_item(name, filename) abort
  let l:temp_uri = langserver#util#get_uri(a:name, a:filename)

  return {
        \ 'uri': l:temp_uri,
        \ 'languageId': &filetype,
        \ 'version': langserver#version#get_version(l:temp_uri),
        \ 'text': langserver#util#get_file_contents(a:filename),
        \ }
endfunction

""
" A parameter literal used in requests to pass a text document and a position inside that document.
"
function! langserver#util#get_text_document_position_params() abort
  return {
        \ 'textDocument': langserver#util#get_text_document_identifier(langserver#util#get_lsp_id()),
        \ 'position': langserver#util#get_position(),
        \ }
endfunction

""
" Read the contents into a variable
function! langserver#util#get_file_contents(filename) abort
  return join(readfile(a:filename), "\n")
endfunction


""
" Parse the stdin of a server
function! langserver#util#parse_message(message) abort
  if type(a:message) ==# type([])
    let l:data = join(a:message, '')
  elseif type(a:message) ==# type('')
    let l:data = a:message
  else
  endif

  let l:parsed = {}
  if l:data =~? '--> request'
    let l:parsed['type'] = 'request'
  elseif l:data =~? '<-- result'
    let l:parsed['type'] = 'result'
  else
    let l:parsed['type'] = 'info'
  endif

  let l:data = substitute(l:data, '--> request #\w*: ', '', 'g')
  let l:data = substitute(l:data, '<-- result #\w*: ', '', 'g')

  if l:parsed['type'] ==# 'request' || l:parsed['type'] ==# 'result'
    let l:data = substitute(l:data, '^\(\S*\):', '"\1":', 'g')
    let l:data = '{' . l:data . '}'
    let l:data = json_decode(l:data)
  endif

  let l:parsed['data'] = l:data 
  return l:parsed
endfunction

function! langserver#util#debug() abort
  return v:false
endfunction

function! langserver#util#get_executable_key(...) abort
  if a:0 > 0
    let l:file_type = a:1
  else
    let l:file_type = &filetype
  endif

  if !exists('g:langserver_executables')
    echoerr '`g:langserver_executables` was not defined'
    return ''
  endif

  for l:k in keys(g:langserver_executables)
    if index(split(l:k, ','), l:file_type) >= 0
      return l:k
    endif
  endfor

  echoerr 'Unsupported filetype: ' . l:file_type
  return ''
endfunction

function! langserver#util#get_lsp_id() abort
  let g:lsp_id_map = get(g:, 'lsp_id_map', {})

  if has_key(g:lsp_id_map, &filetype)
    return g:lsp_id_map[&filetype]
  else
    return -1
  endif
endfunction

function! langserver#util#get_line(loc_bufnr, loc_filename, loc_line) abort
  if bufnr('%') == a:loc_bufnr 
    let l:loc_text = getline(a:loc_line)
  else
    let l:loc_text = readfile(a:loc_filename, '', a:loc_line)[a:loc_line - 1]
  endif

  return l:loc_text
endfunction

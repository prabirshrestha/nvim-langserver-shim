let s:uri_version = {}

""
" Get the current version number and then increment it by one.
"
" @param uri (string): The uri of the file
" @param increment (bool): If true, increment the version
function! langserver#version#get_version(uri, ...) abort
  if a:0 > 0
    let l:increment = a:1
  else
    let l:increment = v:true
  endif

  if !has_key(s:uri_version, a:uri)
    let s:uri_version[a:uri] = 0
  endif

  " Store the value that we're going to return
  " before we increment it
  let l:return_version = s:uri_version[a:uri]

  if l:increment
    let s:uri_version[a:uri] = s:uri_version[a:uri] + 1
  endif

  return l:return_version
endfunction

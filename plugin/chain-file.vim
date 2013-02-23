let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* ChainFile call s:chain_file(<f-args>)
function! s:chain_file(...) 
	return call('chain_file#chain_file', a:000)
endfunction

command! -nargs=+ ChainSet call s:chain_set(<f-args>)
function! s:chain_set(fnames) 
	return call('chain_file#chain_set', a:000)
endfunction

command! -nargs=+ ChainSetEach call s:chain_set_each(<f-args>)
function! s:chain_set_each(fnames) 
	return call('chain_file#chain_set_each', a:00)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo


let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* ChainFile call chain_file#chain_file(<f-args>)
function! s:chain_file(...) 
	return call('chain_file#chain_file', a:000)
endfunction

command! -nargs=+ ChainSet call chain_file#chain_set(<f-args>)
function! s:chain_set(...) 
	return call('chain_file#chain_set', a:000)
endfunction

command! -nargs=+ ChainSetEach call s:chain_set_each(<f-args>)
function! s:chain_set_each(...) 
	return call('chain_file#chain_set_each', a:000)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo


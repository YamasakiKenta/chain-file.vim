let s:save_cpo = &cpo
set cpo&vim


let s:Common = vital#of('chain-file.vim').import('Mind.Common')
"let s:Common = vital#of('vital').import('Mind.Common')
let s:cache_fname     = {}
let s:cache_extension = {}

" setting "{{{
let g:chain_files     = get(g:, 'chain_files', {})
let g:chain_extension = get(g:, 'chain_extension', { 'c' : 'h', 'h' : ['c', 'm'] , 'm' : 'h' })

let g:chain_files = {
			\ 'a.c' : 'include/ab.h',
			\ 'b.c' : 'include/ab.h',
			\ 'ab.h' : ['../a.c', '../b.c'],
			\ }

let g:chain_extension =  { 'c' : 'h', 'h' : ['c', 'm'] , 'm' : 'h' }

let s:chain_files_1 = {
			\ 'ab.h' : '../bc2/a.c',
			\ 'bc2/a.c' : '../include/ab.h',
			\ }

let g:dict1 = { 
			\ '__file'     : g:chain_files,
			\ '__extension' : g:chain_extension,
			\ }

let g:dict2 = { 
			\ '__file'     : s:chain_files_1,
			\ '__extension' : g:chain_extension,
			\ }
"}}}

function! s:get_chain_filename(dicts)  "{{{
	let extension    = expand("%:e")
	let rtn_str      = expand("%")
	let fname_full   = expand("%")

	" 辞書データの設定
	let tmp_d = { '__file' : copy(s:cache_fname) , '__extension' : copy(s:cache_extension) }
	for dict_d in a:dicts
		if type(dict_d) == type({})
			 call s:Common.set_dict_extend(tmp_d.__file,      get(dict_d, '__file',      {}))
			 call s:Common.set_dict_extend(tmp_d.__extension, get(dict_d, '__extension', {}))
		endif
	endfor

	let file_d       = tmp_d.__file
	let extension_d  = tmp_d.__extension

	" KEYを取得する 
	let fname_tmp = s:Common.get_fname_key(file_d, fname_full)

	if exists('file_d[fname_tmp]') 
		" 対応するファイル
		let tmps = s:Common.get_list(file_d[fname_tmp])
		let rtn_str    = expand("%:h").'/'.tmps[0]

		" 並び替え - 最後に開いたファイルを優先させる
		let fname_next = expand(rtn_str)
		let fname_tmp  = s:Common.get_fname_key(file_d, fname_next)
		if exists('file_d[fname_tmp]') 
			" 前回開いたファイルを保存する
			for tmp in s:Common.get_len_sort(s:Common.get_list(file_d[fname_tmp]))
				if  fname_full =~ substitute(tmp, '\.\.[\/\\]', '', '')
					let s:cache_fname[fname_tmp] = tmp
				endif
			endfor
		endif

	elseif exists('extension_d[extension]')
		let extension_next = s:Common.get_list(extension_d[extension])[0]

		"対応する拡張子
		let rtn_str = expand("%:r").".".extension_next

		if exists ('extension_d[extension_next]')
			for tmp in s:Common.get_list(extension_d[extension_next])
				if extension == tmp
					let s:cache_extension[extension_next] = tmp
				endif
			endfor
		endif
	else
	endif

	return rtn_str
endfunction
"}}}

command! -nargs=* ChainFile call s:chain_file(<f-args>)
function! s:chain_file(...) "{{{
	if a:0 > 0
		let dicts = []
		for dict in a:000
			if dict =~ '.'
				exe 'call add(dicts, '.dict.')'
			endif
		endfor
	else
		let dicts = get(g:, 'chain_dict', [{
					\ '__file'      :  get(g:, 'chain_files', {}),
					\ '__extension' :  get(g:, 'chain_extension', { 'c' : 'h', 'h' : 'c'}),
					\ }])
	endif

	exe 'edit' s:get_chain_filename(dicts)
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo


let s:save_cpo = &cpo
set cpo&vim

let s:Common             = vital#of('chain-file.vim').import('Mind.Common')
let s:datafile           = '~/.vim-chain-file'
let s:chain_dict_cache   = {}
let s:chain_dict_default = s:Common.load(s:datafile, {})

function! s:get_dict(dicts) "{{{
	" 辞書データの設定
	let tmp_d = { '__file' : {}, '__extension' : {}, '__pattern' : []}
	for dict_d in a:dicts
		if type(dict_d) == type({})
			call extend(tmp_d.__pattern, get(dict_d, '__pattern', []))
			call s:Common.set_dict_extend(tmp_d.__file,      get(dict_d, '__file',      {}))
			call s:Common.set_dict_extend(tmp_d.__extension, get(dict_d, '__extension', {}))
		endif
	endfor
	return tmp_d
endfunction
"}}}
function! s:sub_chain_set(from, to) "{{{
	let from = a:from
	let to   = a:to
endfunction
"}}}
function! s:get_chain_fname(dicts, cache_d)  "{{{
	let cache_d      = a:cache_d
	let extension    = expand("%:e")
	let rtn_str      = expand("%")
	let fname_full   = expand("%")

	let tmp_d = s:get_dict(a:dicts)
	let patterns     = tmp_d.__pattern
	let file_d       = tmp_d.__file
	let extension_d  = tmp_d.__extension

	" KEYを取得する 
	let fname_tmp = s:Common.get_fname_key(file_d, fname_full)

	if exists('file_d[fname_tmp]') 
		" 対応するファイル
		let tmps = s:Common.get_list(file_d[fname_tmp])
		let rtn_str    = expand("%:h").'/'.tmps[0]

		"優先度の変更
		let fname_tmp = s:Common.get_fname_key(file_d, expand(rtn_str))

		let fname_full = substitute(fname_full, '\\', '\/', 'g')
		let tmps = s:Common.get_len_sort(s:Common.get_list(get(file_d, fname_tmp, [])))
		for tmp in tmps
			let tmp = substitute(tmp, '\\', '\/', 'g')


			if  fname_full =~ substitute(tmp, '\.\.[\/\\]', '', '')
				let cache_d.__file[fname_tmp] = tmp
				break
			endif
		endfor
	else
		let change_flg = 0
		for pattern_d in patterns
			let before = pattern_d.before
			let after  = pattern_d.after

			if fname_full =~ before
				let change_flg = 1
				let rtn_str = substitute(fname_full, before, after, '')
				break
			endif

		endfor
		if change_flg == 0 
			if exists('extension_d[extension]')
				let extension_next = s:Common.get_list(extension_d[extension])[0]

				"対応する拡張子
				let rtn_str = expand("%:r").".".extension_next

				" 優先度の変更
				for tmp in s:Common.get_list(get(extension_d, extension_next, []))
					if extension == tmp
						let cache_d.__extension[extension_next] = tmp
						break
					endif
				endfor
			endif
		endif
	endif

	return rtn_str
endfunction
"}}}

command! -nargs=* ChainFile call s:chain_file(<f-args>)
function! s:chain_file(...) "{{{
	let dicts = []

	" 前回開いたファイル
	let setting_name = a:0 > 0 ? join(a:000, '_') : 'default'
	if exists('s:chain_dict_cache[setting_name]')
		call add(dicts, s:chain_dict_cache[setting_name])
	else 
		let s:chain_dict_cache[setting_name] = {
					\ '__file'      : {},
					\ '__extension' : {},
					\ }
	endif

	if a:0 > 0
		" 引数あり
		for tmp in a:000
			let type_ = type(tmp)
			if type_ == type('')
				exe 'call add(dicts, '.tmp.')'
			elseif type_ == type({})
				call add(dicts, tmp)
			else
			endif
			unlet tmp
		endfor
	else
		" 引数なし

		" 設定ファイル
		call add(dicts, s:chain_dict_default)

		" 辞書型
		if exists('g:chain_dict')
			call add(dicts, {
						\ '__pattern'   : get(g:chain_dict , '__pattern'   , []) , 
						\ '__file'      : get(g:chain_dict , '__file'      , {}) , 
						\ '__extension' : get(g:chain_dict , '__extension' , {}) , 
						\ })
		endif

		" 個別
		call add(dicts, {
					\ '__pattern'   : get(g: , 'chain_patterns'   , []) , 
					\ '__file'      : get(g: , 'chain_files'      , {}) , 
					\ '__extension' : get(g: , 'chain_extensions' , {}) , 
					\ })
	endif

	exe 'edit' s:get_chain_fname(dicts, s:chain_dict_cache[setting_name])
endfunction
"}}}
"
command! -nargs=+ ChainSet call s:chain_set(<f-args>)
function! s:chain_set(fnames) "{{{
endfunction
"}}}
"
command! -nargs=+ ChainSetEach call s:chain_set_each(<f-args>)
function! s:chain_set_each(fnames) "{{{
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo


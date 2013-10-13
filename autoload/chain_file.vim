let s:save_cpo = &cpo
set cpo&vim

let s:Common   = vital#of('chain-file.vim').import('Mind.Common')
let s:datafile = '~/.vim-chain-file'

function! s:get_list(tmp) "{{{
	return (type(a:tmp) == type([])) ? a:tmp : [a:tmp]
endfunction
"}}}
function! s:set_dict_extend(dict1, dict2) "{{{
	" 同じキーがある場合は、リストで結合して返す
	
	" 大きい方をdict1 に設定する
	let [dict1, dict2] = [a:dict1, a:dict2]

	" a:dict1 を優先させる
	let dict_new = dict1
	for key in keys(dict2)
		let dict_new[key] = exists('dict_new[key]')
					\ ? extend(s:get_list(a:dict1[key]), s:get_list(a:dict2[key])) 
					\ : dict2[key]
	endfor

	return dict_new
endfunction
"}}}
function! s:get_fname_key(file_d, fname_full) "{{{
	" 辞書型に登録しているキーを、検索する 
	" ( キーが見つかるまで、ファイル名を短くする ) 

	let file_d    = a:file_d
	let fname_tmp  = substitute(a:fname_full, '\\', '\/', 'g')

	while len(fname_tmp) && !exists('file_d[fname_tmp]')
		let fname_tmp  = matchstr(fname_tmp, '.\{-}[\/\\]\zs.*')
	endwhile
	return fname_tmp
endfunction
"}}}

function! s:init() "{{{
	if exists('s:init_flg')
		return 
	endif
	let s:init_flg = 1

	let s:chain_dict_cache   = {}

	let tmp = s:Common.load(s:datafile, {})

	let s:chain_dict_default = {
				\ '__pattern'      : get(tmp, '__pattern', []),
				\ '__file'         : get(tmp, '__file', {}),
				\ '__extension'    : get(tmp, '__extension', {}),
				\ }
endfunction
"}}}
function! s:get_dict(dicts) "{{{
	" 辞書データの設定
	let tmp_d = { '__file' : {}, '__extension' : {}, '__pattern' : []}
	for dict_d in a:dicts
		if type(dict_d) == type({})
			call extend(tmp_d.__pattern, get(dict_d, '__pattern', []))
			call s:set_dict_extend(tmp_d.__file,      get(dict_d, '__file',      {}))
			call s:set_dict_extend(tmp_d.__extension, get(dict_d, '__extension', {}))
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
	let rtn_str      = expand("%:p") " 失敗した場合は、現在のファイル名を返す
	let fname_full   = expand("%:p")

	let tmp_d        = s:get_dict(a:dicts)
	let patterns     = tmp_d.__pattern
	let file_d       = tmp_d.__file
	let extension_d  = tmp_d.__extension

	let fname_full = substitute(fname_full, '\\', '\/', 'g')

	" 現在のファイル名から、辞書データから検索し、KEY を取得する
	let fname_tmp = s:get_fname_key(file_d, fname_full)

	if exists('file_d[fname_tmp]') 
		" 対応するファイル
		let tmps = s:get_list(file_d[fname_tmp])

		" 開くファイル名の取得
		let rtn_str = expand("%:h").'/'.tmps[0]

		" === 現在のファイルが開くようにする ===
		"
		" 開くファイル名
		let fname_tmp = s:get_fname_key(file_d, expand(rtn_str))

		let tmps = s:Common.get_len_sort(s:get_list(get(file_d, fname_tmp, [])))
		for tmp in tmps
			let tmp = substitute(tmp, '\\', '\/', 'g')

			if  fname_full =~ substitute(tmp, '\.\.\/', '', '')
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
				let extension_next = s:get_list(extension_d[extension])[0]

				"対応する拡張子
				let rtn_str = expand("%:r").".".extension_next

				" 優先度の変更
				for tmp in s:get_list(get(extension_d, extension_next, []))
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
function! s:get_fname_now()"{{{
	return expand("%:t")
endfunction
"}}}
function! s:set_chain_file(key, val) "{{{
	if exists('s:chain_dict_default.__file[a:key]')
		let tmp = s:chain_dict_default.__file[a:key]

		if ( type(tmp) != type([]) ) 
			unlet s:chain_dict_default.__file[a:key]
			let s:chain_dict_default.__file[a:key] = [tmp]
		endif

		call s:Common.add_uniq(s:chain_dict_default.__file[a:key], a:val)
	else
		let s:chain_dict_default.__file[a:key] = a:val
	endif
endfunction
"}}}

function! chain_file#chain_file(...) "{{{
	" ********************************************************************************
	" @par       
	" @param[in] 設定データ, 設定データの変数名
	" @retval    
	" ********************************************************************************
	call s:init()

	let dicts = []

	" 履歴 "{{{
	" 引数毎に履歴データを読む
	let setting_name = a:0 > 0 ? join(a:000, '_') : 'default' 

	" 履歴データを読む
	if exists('s:chain_dict_cache[setting_name]')
		call add(dicts, s:chain_dict_cache[setting_name])
	else 
		let s:chain_dict_cache[setting_name] = {
					\ '__file'      : {},
					\ '__extension' : {},
					\ }
	endif
	"}}}

	" 設定データを作成する
	if a:0 > 0
		" 引数あり "{{{
		for tmp in a:000
			let type_ = type(tmp)
			if type_ == type('')
				" 変数名の場合は、中身のデータを挿入
				exe 'call add(dicts, '.tmp.')'
			elseif type_ == type({})
				" 変数名の場合は、中身のデータを挿入
				call add(dicts, tmp)
			endif
			unlet tmp
		endfor
		"}}}
	else
		" 引数なし "{{{
		" 辞書型
		if exists('g:chain_dict')
			call add(dicts, {
						\ '__pattern'   : get(g:chain_dict , '__pattern'   , []) , 
						\ '__file'      : get(g:chain_dict , '__file'      , {}) , 
						\ '__extension' : get(g:chain_dict , '__extension' , {}) , 
						\ })
		endif

		call add(dicts, s:chain_dict_default)
		"}}}
	endif

	let fname = simplify(s:get_chain_fname(dicts, s:chain_dict_cache[setting_name]))
	if len(fname)
		exe 'edit'  fname
	endif
endfunction
"}}}
"
function! chain_file#chain_set(fnames) "{{{
	call s:init()
	" 現在のファイルに紐づくファイルを設定する
	let fname_now = s:get_fname_now()
	call s:set_chain_file(fname_now, a:fnames)
	call s:Common.save(s:datafile, s:chain_dict_default)
endfunction
"}}}
"
function! chain_file#chain_set_each(fnames) "{{{
	" 現在のファイルに紐づくファイルを設定する 
	let fname_now = s:get_fname_now()
	call s:set_chain_file(fname_now, a:fnames)
	for fname in s:get_list(a:fnames)
		call s:set_chain_file(fname, fname_now)
	endfor
	call s:Common.save(s:datafile, s:chain_dict_default)
endfunction
"}}}

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
else
	set cpo&
endif

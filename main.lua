require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.View_*"
import "android.media.*"
import "android.view.*"
import "android.content.*"
import "java.io.*"
import "java.util.*"
import "java.lang.*"
import "android.content.Context"
import "android.provider.*"
require "layout"
import "java.lang.System"
activity.setTitle("播放器")
--activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
--activity.setTheme(android.R.style.Theme_Material_NoActionBar)
--[[
-- create a lyric table

layout_lyric = {
  RelativeLayout;
  id="w_lyric";
  layout_width="fill_parent";
  layout_height="fill_parent";
  layout_centerVertical=true;
  layout_centerHorizontal=true;
  gravity="top|center";
}

lyric_unit = {
  TextView;
  --id="tv_lyric";
  text="Text";
  layout_height="wrap_content";
  --padding="10dp";
  textColor="#FFFFFF";
  --textColor="#B38A46";
  --layout_alignParentTop=true;
  textSize="20sp";
  layout_width="wrap_content";
  --background="#605756";
  layout_centerVertical=true;
  layout_centerHorizontal=true;
  gravity="center_horizontal";
  --alpha="0.9";
}
lyric_list = {
  {
    TextView;
    id="tv_lyric";
    text="Text";
    layout_height="wrap_content";
    --padding="10dp";
    textColor="#B38A46";
    --layout_alignParentTop=true;
    textSize="20sp";
    layout_width="wrap_content";
    --background="#605756";
    layout_centerVertical=true;
    layout_centerHorizontal=true;
    gravity="center_horizontal";
  };
}

--print(layout_lyric['gravity'])
-- Create upper
max_ext = 1
for i=max_ext, 1, -1 do
  unit = lyric_unit
  unit['id'] = 'tv_lyric_u'..i
  print('upper:', unit['id'])
  if i == 1 then
    unit['layout_above'] = 'tv_lyric'
  elseif i <= max_ext then
    unit['layout_above'] = 'tv_lyric_u'..tostring(i-1)
  end
  lyric_list[#lyric_list+1] = unit
end]]
-- create down
--[[
for i=1, max_ext do
  unit = lyric_unit
  unit['id'] = 'tv_lyric_d'..i
  if i == 1 then
    unit['layout_below'] = 'tv_lyric'
  elseif i <= max_ext then
    unit['layout_below'] = 'tv_lyric_d'..tostring(i-1)
  end
  lyric_list[#lyric_list+1] = unit
end]]
--[[
for i=max_ext, 1, -1 do
  unit = lyric_unit
  unit['id'] = 'tv_lyric_d'..i
  if i == 1 then
    unit['layout_below'] = 'tv_lyric'
  elseif i <= max_ext then
    unit['layout_below'] = 'tv_lyric_d'..tostring(i-1)
  end
  lyric_list[#lyric_list+1] = unit
end]]
--[[
for i=1, #lyric_list do
  layout_lyric[i+1] = lyric_list[i]
end
]]
--main[3] = layout_lyric

activity.setContentView(loadlayout(main))
back.setImageBitmap(loadbitmap("back.png"))
w_lyric.setVisibility(View.INVISIBLE)

this.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON); 

--print("h")

function getAppPath()
  return tostring(this.getExternalFilesDir("Settings"))..'/'
end

local arr=nil
local pd--扫描进度条,定义在这容易操作
local mp=MediaPlayer()
local t=nil
local isPlay=false
local curPlay=nil --当前正在播放的mp3的路径
local listpath=getAppPath().."playlist.txt"
local tf=File(listpath)
local dur--歌曲长度
local cur--播放当前位置
local min,sec=0,0--分和秒
local curIdx=0--当前播放的mp3在列表中的索引
local th=nil--线程
local th_lrc = nil
local has_lrc = false
local lrc_data = {}
local lrc_lines = {
  tv_lyric_u9, tv_lyric_u8, tv_lyric_u7, 
  tv_lyric_u6, tv_lyric_u5, tv_lyric_u4, 
  tv_lyric_u3, tv_lyric_u2, tv_lyric_u1,
  tv_lyric, 
  tv_lyric_d1, tv_lyric_d2, tv_lyric_d3,
  tv_lyric_d4, tv_lyric_d5, tv_lyric_d6, 
  tv_lyric_d7, tv_lyric_d8, tv_lyric_d9, 
}
--[==[for i=1, max_ext*2+1 do
  print([[main[3][i], lrc_lines[i] ]], tv_lyric_d2)
end]==]
local sline = 1
local lrc_changed = true
local lrc_starting = false
local lrc_jump = false

local titles = {
  '就随便听听好了＾０＾~',
  "享受平凡音质",
  "享受高品人生",
  "才、才没有期待见到您呢！",
  "123,321,1234567..."
}

math.randomseed(os.time())
tv_title.setText(titles[math.random(1, #titles)])

--播放音乐，不异步可控
--@mp MediaPlayer对象
--@path 歌曲完整路径
function play(mp,path)
  loadNewLrc()
  --loadNewLrc()
  mp.reset()
  mp.setDataSource(path)
  mp.prepare()
  mp.start()
end
--更新内容
function updateProgress(path)
  pd.setMessage(path)
end
--回调函数，获取某文件夹下所有mp3文件完成时被调用
function getListFinish()
  writeFile(listpath,arr)
  pd.cancel()
  th.quit()--退出线程
  print("扫描完毕")
end
--获取文件夹下的所有mp3文件。并存在arr中
--利用广度优先搜索
function getFiles(arr,path)
  require "import"
  import "java.util.*"
  import "java.io.*"
  local queue=LinkedList()--模拟一个队列
  local f=File(path)
  local ls=f.listFiles()
  for i=0,#ls-1 do
    local t=ls[i]
    local name=t.getName();
    if t.isDirectory() then--是文件夹
      queue.addLast(t)
    else
      if string.find(string.lower(name),"%.mp3$") and t.length()>1024*1024*2 then
        arr.add(t)
      end--if
    end--if
  end--for
  while(queue.isEmpty()==false) do
    local dirtemp= queue.removeFirst()

    call("updateProgress","已扫描到"..arr.size().."个mp3文件\n"..dirtemp.getPath())
    local listtemp=dirtemp.listFiles()
    for i=0,#listtemp-1 do
      local t=listtemp[i]
      local name=t.getName();
      if t.isDirectory() then--是文件夹
        queue.addLast(t)
      else
        if string.find(string.lower(name),"%.mp3$") and t.length()>1024*1024*2 then
          arr.add(t)
        end--if
      end--if
    end--for
  end--while
  call("getListFinish")
end --getFiles


--获取某文件夹下所有mp3文件。并存在arr中
function getList(path)
  arr=ArrayList()
  th=thread(getFiles,arr,path)
  th.getFiles(arr,path)
end

--写入文件
--@path  文件完整路径
--@list    ArrayList
function writeFile(path,list)
  local fw=FileWriter(path)
  local bw=BufferedWriter(fw)
  for i=0,list.size()-1 do
    str=list.get(i).toString()
    bw.write(str,0,utf8.len(str))
    bw.newLine()
  end
  bw.flush()
  bw.close()
end
--读文件
--path 完整路径
--return ArrayList
function readFile(path)
  local al=ArrayList()
  local fr=FileReader(path)
  local br=BufferedReader(fr)
  local ch=0
  while(br.read()~=-1 )
  do
    al.add(br.readLine())
  end
  br.close()
  return al
end

-- read lrc file
-- @pa path
function readLrc(path)
  list=ArrayList()
  freader=FileReader(path)
  --is = InputStream(path)
  --isr = InputStreamReader(is)
  --bread=BufferedReader(freader)
  bread = BufferedReader(InputStreamReader(FileInputStream(path), "GB2312"))
  --bread=BufferedReader(isr)
  ch2=0
  while(bread.read()~=-1)
  do
    line = bread.readLine()
    import "org.apache.http.util.EncodingUtils"
    line = tostring(EncodingUtils.getString(String(line).getBytes(), "utf8"))
    list.add(line)
    --list.add(bread.readLine())
  end
  bread.close()
  -- read into al first
  for i=0,list.size()-1 do
    data = list.get(i)
    --print(data)
    --print(data)
    time_str = string.match(data, '(.+)]')
    if time_str ~= nil then
      -- continue??
      t_min = tointeger(string.match(time_str, "(.+):"))
      t_sec = tonumber(string.match(time_str, ":(.+)"))
      if t_min == nil or t_sec == nil then 
        t_min = 0
        t_sec = 0
      end
      if t_min ~= nil and t_sec ~= nil then
        g_time = t_min * 60 + t_sec
        --print(time_str, g_time)
        words = string.match(data, '](.+)')
        --print(words)
        --break
        if words ~= nil then
          table.insert(lrc_data, {tointeger(g_time * 1000), words})
        end
      end
    end
  end
  --print(lrc_data[1][2])
  return nil
end

function loadNewLrc()
  --print(curPlay)
  lrc_data = {}
  sline = 0
  for i=1, #lrc_lines do
    lrc_lines[i].setText('')
  end
  lrc_starting = true
  if th_lrc ~= nil then
    --print("!")
    th_lrc.Enabled = false
    th_lrc.stop()
    th_lrc = nil
    sline = 0
  end
  lrc_starting = true
  sline = 0
  lrc_changed = true
  --print("Start New!")
  th_lrc=timer(_run_ms,0,100,min,sec)
  th_lrc.Enabled=true
  sline = 0
  --os.execute('sleep 1')

  if curPlay == nil then return end
  --print('loadNewLrc(): curPlay='..curPlay)
  lrc_path = tostring(string.gsub(curPlay, '.mp3$', '.lrc'))
  lrc_file = File(lrc_path)
  if lrc_file.exists() == true then
    has_lrc = true
    --print('Has a lrc file')
    back.setImageBitmap(nil)
    tv_lyric.setText("Loading...")
    readLrc(lrc_path)
    w_lyric.setVisibility(View.VISIBLE)
  else
    has_lrc = false
    --print('No lrc')
    back.setImageBitmap(loadbitmap("back.png"))
    tv_lyric.setText("")
    tv_lyric.setVisibility(View.INVISIBLE)
  end
end

--显示歌曲列表
--@path 列表文件路径
--@mediaplayer
function showList(path,mp)
  local al= readFile(path)
  arr=al
  local names={}
  local paths={}
  for i=0,al.size()-1 do
    table.insert(paths,al.get(i))
    table.insert(names,File(al.get(i)).getName())

  end
  local ad= AlertDialog.Builder(activity)
  ad.setTitle("歌曲列表")
  ad.setItems(String(names)
  ,DialogInterface.OnClickListener{
    onClick=function(dialog,which)
      curPlay=paths[which+1]
      curIdx=which
      play(mp,curPlay)
      -- tt is name
      local tt=string.gsub(names[which+1],".mp3$","")--偷懒一下
      --[[
      lrc_path = tostring(string.gsub(curPlay, '.mp3$', '.lrc'))
      lrc_file = File(lrc_path)
      if lrc_file.exists() == true then
        has_lrc = true
        print('Has a lrc file')
        back.setImageBitmap(nil)
        readLrc(lrc_path)
      else
        has_lrc = false
        print('No lrc')
        back.setImageBitmap(loadbitmap("back.png"))
      end]]

      tv_title.setText(tt)
    end
  })

  ad.setNegativeButton( "取消", nil)
  ad= ad.create()
  local window = ad.getWindow()
  local lp = window.getAttributes()
  --设置透明度
  lp.alpha = 0.8
  window.setAttributes(lp)
  ad.show()
end
--弹出进度条
--@text 进度条的文本
function showProcessBar(text)
  pd = ProgressDialog
  .show(activity, nil, text)
  pd.setCancelable(false)--扫描中不能取消
end


--弹出文本框对话框
--@pa 进度条对象
function showEditDialog(msg)
  --[[
  local edit=EditText(activity)
  edit.setText("/sdcard/")
  local dl =AlertDialog.Builder(activity)
  dl.setTitle(msg)
  dl.setView(edit)
  dl.setPositiveButton("确定",
  DialogInterface.OnClickListener{
    onClick=function(dialog,which)
      showProcessBar("扫描音乐中，请稍候……")
      getList(edit.getText().toString())
    end
  })
  dl.show()]]
  target = '/sdcard/'
  --print(getAppPath()..'last_dir.txt')
  if File(getAppPath()..'last_dir.txt').exists() == true then
    fp = BufferedReader(FileReader(getAppPath()..'last_dir.txt'))
    target = fp.readLine()
    --print('read:', target)
  end
  --if target[-1] ~= '/' then target = target..'/' end
  --print('target=', string.target)
  activity.newActivity('select_dir', {target})
end

function onResult(name, data)
  if name == 'select_dir' then
    if data == "Failed" then return end
    path = data
    print("目录设置为 " .. path)
    io.open(getAppPath() .. 'last_dir.txt', 'w'):write(path):close()
    showProcessBar("扫描音乐中，请稍候……")
    getList(path)
  end
end

------全局代码------
if tf.exists()==false then--文件列表不存在
  --showEditDialog("初次使用软件，设置扫描音乐的路径")
  print("初次使用软件，设置扫描音乐的路径")
  showEditDialog()
else
  arr= readFile(listpath)
end
----------------------------

--实时更新进度条和时间显示
function updateTime(m,s)
  if m<10 then m="0"..m end
  if s<10 then s="0"..s end
  tv_startTime.setText(m..":"..s)
  pb_time.setProgress(mp.getCurrentPosition())
  --print(th_lrc)
end

function updateTimeMs(ms)
  --change = false
  --print(sline)
  if has_lrc == true then
    --tv_lyric.setText(tostring(ms))
    if sline + 1 >= #lrc_data then return end
    if lrc_starting == true then
      lrc_starting = false
      return
    end
    if sline == nil then sline = 0 end
    if #lrc_data ~= 0 then
      --break
      if lrc_jump == true then
        while sline + 1 < #lrc_data and lrc_data[sline+1][1] < ms do
          sline = sline + 1
          lrc_changed = true
        end
        lrc_jump = false
      end
      for t=1, 1 do 
        if sline + 1 < #lrc_data and lrc_data[sline+1][1] < ms then
          --print(lrc_data[sline+1][1])
          sline = sline + 1
          lrc_changed = true
        end
      end
    end
    if lrc_changed == true then
      --tv_lyric.setText(tostring(lrc_data[sline][2]))
      for i=1, #lrc_lines do
        --print(lrc_lines[i])
        idx = sline + i - 1 - tointeger(#lrc_lines-1) / 2
        lrc_lines[i].setText('')
        if idx <= #lrc_data and idx > 0 and lrc_lines[i] ~= nil then
          lrc_lines[i].setText(tostring(lrc_data[idx][2]))
        end
        --lrc_lines[i].setText(tostring(i))
      end
      --print(lrc_lines[1])
      --tv_lyric.setText(tostring(System.currentTimeMillis()))
    end
  end
end

--计时器代码
function _run(m,s)
  function run()
    s=s+1
    if(s==60) then
      m=m+1
      s=0
    end
    call("updateTime",m,s)
  end
end

function get_ms()
  --print(System.currentTimeMillis())
  return System.currentTimeMillis()
end

local delta = 0
local ms_start = 0
function init_ms(ms)
  --print("init_ms", ms)
  ms_start = System.currentTimeMillis()
end
function calc_delta(ms)
  --ms_start = System.currentTimeMillis() + ms
  if ms_start == 0 then
    init_ms(ms)
    return
  end
  ms_now = System.currentTimeMillis()
  delta = ms_now - ms_start + ms
  if delta <= 0 then 
    ms_start = 0
    return 
  end
  --print(delta)
  updateTimeMs(delta)
end

--get_ms()

--计时器代码2 ms
function _run_ms(m,s)
  --sline2 = 0
  ms = 1000 * (60 * m + s)
  call("init_ms", ms)
  --ms_start = System.currentTimeMillis() + ms
  function run()
    --ms=ms+100

    --ms_now = System.currentTimeMillis()
    --print(ms_now - ms_start, ms)
    --Notice: os_clock can't work probably!
    --print(ms_now)
    --delta = ms_now - ms_start
    --call("updateTimeMs", delta)
    call("calc_delta", ms)
    --print(delta)
    --print('sline=', sline2)
  end
end

--上一曲
function on_pre(v)
  --loadNewLrc()
  if(curIdx>=0) then
    curIdx=curIdx-1
    if curIdx == -1 then curIdx = arr.size()-1 end
    local tt=string.gsub(File(arr.get(curIdx)).getName(),".mp3$","")--偷懒一下
    tv_title.setText(tt)
    curPlay=arr.get(curIdx)
    play(mp,arr.get(curIdx))
  end
  --local curPlay = tostring(File(arr.get(curIdx)))
  --print(curPlay)
  --loadNewLrc(curPlay)
end

--下一曲
function on_next(v)
  --loadNewLrc()
  --print(curIdx)
  --if curIdx == -1 then curIdx = 0 end
  if(curIdx<=arr.size()-1) then
    --[[if curIdx==0 and not mp.isPlaying() then
      -- ???
      play(mp,arr.get(0))
      --curIdx = 1
      local tt=string.gsub(File(arr.get(0)).getName(),".mp3$","")--偷懒一下
      tv_title.setText(tt)
    else]]
    curIdx=curIdx+1
    if curIdx == arr.size() then curIdx = 0 end
    --local curPlay = tostring(File(arr.get(curIdx)))
    curPlay=arr.get(curIdx)
    local tt=string.gsub(File(arr.get(curIdx)).getName(),".mp3$","")--偷懒一下
    tv_title.setText(tt)
    --print('curPlay='..curPlay..' tt='..tt)
    play(mp,arr.get(curIdx))
    --end
  end
  --curPlay = tostring(File(arr.get(curIdx)))
  --loadNewLrc(curPlay)
end

--设置mediaPlayer播放结束时的回调函数
mp.setOnCompletionListener(MediaPlayer.OnCompletionListener{
  onCompletion=function(mper)
    --     print("歌曲播放结束")
    pb_time.setProgress(mp.getCurrentPosition())
    t.Enabled=false
    t.stop()
    t=nil
    th_lrc.Enabled=false
    th_lrc.stop()
    th_lrc=nil
    on_next(nil)
  end})

--时间转换函数
function formatTime(time)
  local min,sec=0,0
  sec=math.floor(time/1000)
  if(sec>60) then
    min=math.floor(sec/60)
    sec=math.floor(sec%60)
  end
  if min<10 then min="0"..min end
  if sec<10 then sec="0"..sec end
  return min..":"..sec
end
--时间设置
function setTime(time)
  local min,sec=0,0
  sec=math.floor(time/1000)
  if(sec>60) then
    min=math.floor(sec/60)
    sec=math.floor(sec%60)
  end

  return min,sec
end
--歌曲开始播放
mp.setOnPreparedListener(MediaPlayer.OnPreparedListener{
  onPrepared=function(mper)
    dur=mper.getDuration()--获取歌曲的时常
    pb_time.setMax(dur)
    local tt=formatTime(dur)
    tv_startTime.setText("00:00")
    tv_endTime.setText(tt)
    bn_pause.setText("H")
    min,sec=0,0
    if t~=nil then --计时器不为空就停止
      t.Enabled=false
      t.stop()
      t=nil
    end
    if th_lrc~=nil then --计时器不为空就停止
      th_lrc.Enabled=false
      th_lrc.stop()
      th_lrc=nil
    end
    --歌曲开始播放又计时
    t=timer(_run,0,1000,min,sec)
    t.Enabled=true
    if th_lrc ~= nil then
      --print("!")
      th_lrc.Enabled = false
      th_lrc.stop()
      th_lrc = nil
    end
    --print("Start New!")
    th_lrc=timer(_run_ms,0,100,min,sec)
    th_lrc.Enabled=true
  end})

--按下暂停时发生
function on_pause(v)
  if(mp.isPlaying()) then
    mp.pause()
    bn_pause.setText("D")
    if(t~=nil) then
      t.Enabled=false
    end
    if(th_lrc~=nil) then
      th_lrc.Enabled = false
    end
  else
    if(t~=nil) then--如果为空那就是播放完了的情况
      mp.start()
      bn_pause.setText("H")
      t.Enabled=true
      --th_lrc.Enabled = true
    else
      curIdx = -1
      on_next(nil)
    end
  end
end

--按下"列表"按钮
function on_playlist(v)
  local f=File(String(listpath))
  local isExist= f.exists()
  if(isExist==true) then
    showList(listpath,mp)
  else
    print("列表文件不存在，请重新获取")
  end
end

function on_Menu(v)
  local items={"更新列表","关于","退出"}
  local ad= AlertDialog.Builder(activity)
  ad.setTitle("菜单")
  ad.setItems(String(items)
  ,DialogInterface.OnClickListener{
    onClick=function(dialog,which)
      if which==0 then
        showEditDialog("输入路径以重新扫描")
      elseif which==1 then
        print([[落叶似秋制作，无版权，修改请注明原作者
20170316更新：优化文件扫描器，更快速的扫描
LanceLiang2018更新(20190721)：增加了功能：
歌词显示，美化，文件夹选择，标题滚动...]])
      elseif which==2 then
        if t~=nil then
          t.stop()
        end
        if th_lrc~=nil then
          th_lrc.stop()
        end
        mp.stop()
        mp.release()--释放资源
        activity.finish()
      end--判断选了哪项的if
    end--onClick
  })
  ad.setNegativeButton( "取消", nil)
  ad= ad.create()
  ad.show()
end

exit = 0

function onKeyDown(code,event)
  if string.find(tostring(event),"KEYCODE_BACK") ~= nil then 
    --并不会发生什么...
    if exit+2 > tonumber(os.time()) then 
      if t~=nil then
        t.stop()
      end
      if th_lrc ~= nil then
        th_lrc.stop()
      end
      mp.stop()
      mp.release()--释放资源
      activity.finish()
    else
      print("再按一次退出程序")
      exit=tonumber(os.time())
    end
    return true
  end
end


--进度跳转
pb_time.setOnSeekBarChangeListener(
SeekBar.OnSeekBarChangeListener{
  onStopTrackingTouch=function(bar)
    if mp.isPlaying() then
      local cur=bar.getProgress()
      local tt=formatTime(cur)
      min,sec=setTime(cur)
      tv_startTime.setText(tt)
      mp.seekTo(cur)

      lrc_jump = true

      if t~=nil then --计时器不为空就停止
        t.Enabled=false
        t.stop()
        t=nil
      end
      --重新计时
      t=timer(_run,0,1000,min,sec)
      t.Enabled=true
      if th_lrc ~= nil then
        --print("!")
        th_lrc.Enabled = false
        th_lrc.stop()
        th_lrc = nil
      end
      sline = 0
      lrc_changed = true
      --print("Start New!")
      th_lrc=timer(_run_ms,0,100,min,sec)
      th_lrc.Enabled=true
    end
  end})

--print(this.getExternalFilesDir("J"))
--activity.newActivity('select_dir', {'/sdcard/'})
--print(System.currentTimeMillis())
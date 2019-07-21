require "import"
import "android.widget.*"
import "android.view.*"

path = ''
ori_path = ''

layout_select = {
  LinearLayout;
  orientation="vertical";
  background="#FF303030";
  {
    LinearLayout;
    layout_width="fill";
    {
      TextView;
      textSize="15dp";
      text="目录:";
      id="text_path";
    };
  };
  {
    LinearLayout;
    gravity="center";
    layout_width="fill";
    {
      Button;
      text="上一级";
      id="btn_up";
      layout_weight="1.0";
    };
    {
      Button;
      text="确定";
      id="btn_select";
      layout_weight="1.0";
    };
    {
      Button;
      text="取消";
      id="btn_exit";
      layout_weight="1.0";
    };
    {
      Button;
      text="根目录";
      id="btn_root";
      layout_weight="1.0";
    };
    {
      Button;
      text="手动";
      id="btn_input";
      layout_weight="1.0";
    }
  };
  {
    LinearLayout;
    layout_height="fill";
    layout_width="fill";
    {
      ListView;
      id="list";
      layout_height="fill";
      layout_width="fill";
    };
  };
};

item = {
  LinearLayout;
  layout_width="fill";
  layout_height="fill";
  gravity="center";
  {
    LinearLayout;
    gravity="left";
    layout_height="40dp";
    orientation="horizontal";
    layout_width="-1";
    {
      TextView;
      textSize="15dp";
      layout_marginLeft="10dp";
      text="标题内容(nil)";
      layout_gravity="center";
      id="text";
      ellipsize="end";
    };
  };
};

base_path = {'/sdcard/', '/storage/'}

function set_path_text()
  text_path.setText("Path: " .. path)
end

function up_path()
  if path == "/sdcard/" or path == '/storage/' then return end
  --new_path = path:match("(.+)/(.+)/") .. '/'
  --path = new_path
  --print(File(path).getParent()..'/')
  path = tostring(File(path).getParent())..'/'
  if path == '/storage/emulated/' then 
    up_path()
  end
end

function load_path()
  data = {}
  adp = LuaAdapter(activity, data, item)
  files = get_dir()
  --print(files[1])
  for i=1, #base_path do
    if path == base_path[i] then
      adp.add{text="emulated/0"}
    end
  end
  for i, v in ipairs(files) do
    --name = tostring(v):match(path .. "(.+)")
    name = File(tostring(v)).getName()
    --name = tostring(v)
    adp.add{text=name}
    --print(v)
  end
  list.Adapter = adp
  list.onItemClick = function(l, v, p, i)
    str = tostring(v.Tag.text.Text)
    new_path = path .. str .. '/'
    --print(new_path)
    --activity.newActivity("select_dir", {new_path})
    path = new_path
    load_path()
    set_path_text()
  end
end

function main(data)
  path = tostring(data)
  --ori_path = path
  --print(ori_path)
  --activity.setTheme(android.R.style.Theme_Material)
  activity.setTitle("选择目录")
  activity.setContentView(loadlayout(layout_select))

  load_path()
  set_path_text()
  btn_exit.onClick = function() activity.result{"Failed"} end
  btn_select.onClick = function() activity.result{path} end
  btn_up.onClick = function()
    up_path()
    load_path()
    set_path_text()
    --print(new_path)

  end
  btn_input.onClick = function()
    local edit = EditText(activity)
    edit.setText(path)
    import "android.app.AlertDialog"
    import "android.content.DialogInterface"
    local dl = AlertDialog.Builder(activity)
    dl.setTitle("直接输入路径（用于访问SD卡）")
    dl.setView(edit)
    dl.setPositiveButton("确定",
    DialogInterface.OnClickListener{
      onClick = function(dialog,which)
        path = edit.getText().toString()
        load_path()
        set_path_text()
      end
    })
    dl.show()
  end
  btn_root.onClick = function()
    if path == '/sdcard/' then
      path = '/storage/'
    else
      path = '/sdcard/'
    end
    load_path()
    set_path_text()
  end
end

function get_dir()
  import("java.io.File")
  if File(path).exists() == false then return {} end
  li = luajava.astable(File(path).listFiles())
  res = {}
  if li == nil then return res end
  res_last = 1
  for i, v in ipairs(li) do
    if File(tostring(v)).isDirectory() then
      res[res_last] = v
      res_last = res_last + 1
    end
  end
  table.sort(res, function(a,b)
    return (a.isDirectory()~=b.isDirectory() and a.isDirectory()) or ((a.isDirectory()==b.isDirectory()) and a.Name<b.Name)
  end)
  return res
end

function onResult(name, data)
  if name == 'select_dir' then
    activity.result{data}
  end
end

--添加返回键判断事件
function onKeyDown(code,event) 
  if string.find(tostring(event),"KEYCODE_BACK") ~= nil then 
    will_exit = false
    for i=1, #base_path do
      if path == base_path[i] then
        activity.finish()
        will_exit = true
      end
    end
    if will_exit == false then
      up_path()
      load_path()
      set_path_text()
    end
    return true
  end
end
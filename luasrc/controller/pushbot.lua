module("luci.controller.pushbot",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/pushbot") then
		return
	end

	entry({"admin", "services", "pushbot"}, alias("admin", "services", "pushbot", "setting"),_("全能推送"), 30).dependent = true
	entry({"admin", "services", "pushbot", "setting"}, cbi("pushbot/setting"),_("配置"), 40).leaf = true
	entry({"admin", "services", "pushbot", "advanced"}, cbi("pushbot/advanced"),_("高级设置"), 50).leaf = true
	entry({"admin", "services", "pushbot", "client"}, form("pushbot/client"), "在线设备", 80)
	entry({"admin", "services", "pushbot", "log"}, form("pushbot/log"),_("日志"), 99).leaf = true
	entry({"admin", "services", "pushbot", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", "pushbot", "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "services", "pushbot", "status"}, call("act_status")).leaf = true


end

function act_status()
	local e={}
	e.running=luci.sys.call("busybox ps|grep -v grep|grep -c pushbot >/dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_log()
	local log_path = "/tmp/pushbot/pushbot.log"
	local log_content = ""
	
	-- 检查日志文件是否存在
	if nixio.fs.access(log_path) then
		log_content = luci.sys.exec("cat " .. log_path)
	else
		-- 检查是否启用了日志
		local debuglevel = luci.sys.exec("uci -q get pushbot.pushbot.debuglevel")
		if debuglevel:match("^%s*$") or debuglevel:match("^0") then
			log_content = "日志功能未启用。\n请在「配置」页面中启用「开启日志」选项。"
		else
			log_content = "日志文件不存在: " .. log_path .. "\n请检查 PushBot 服务是否正在运行。"
		end
	end
	
	luci.http.prepare_content("text/plain; charset=utf-8")
	luci.http.write(log_content)
end

function clear_log()
	local log_path = "/tmp/pushbot/pushbot.log"
	if nixio.fs.access(log_path) then
		luci.sys.call("echo '' > " .. log_path)
		luci.sys.call("echo '$(date \"+%Y-%m-%d %H:%M:%S\") 【系统】日志已清空' >> " .. log_path)
	end
end

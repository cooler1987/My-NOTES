帕斯云网站不能在电脑浏览器签到的解决方法（已验证）

网站地址：cloud.pasyun.com

在签到页F12，然后选择源代码/来源，代码段，新代码段，将下面代码中的UID替换成自己的后输入，按Ctrl+Enter确认，以后就可以点签到了。

```
function check() {
    var url = window.location.href;
    var uid = xxx;  //这里的UID替换成自己的UID，在主页可以看到自己的UID
    $.ajax({
        url: url
        ,type: 'post'
        ,data: {uid:uid}
        ,dataType: 'json'
        ,success: function(data){
            if(data.code != 200)
            {
                alert(data.msg);
                return false;
            }else{
                alert(data.msg);
            }
        }
        ,error: function(){
            alert('请求失败');
        }
    })
}
```

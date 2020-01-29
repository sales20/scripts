using System;
using System.IO;
using FaucetCollector.Script;
using OpenQA.Selenium;
//css_inc ShortLinkUtilities
//css_inc RecaptchaUtilities

public class FlyDash : FaucetScript {
    /// <summary>
    /// List of Settings that will be shown in the bot when selecting this Faucet in the bot.
    /// You can get the value the user entered with the methods: GetSetting("[Name of the FaucetSetting]"), GetBoolSetting and GetDateTimeSetting
    /// You can also create a new setting value using SetSetting("[Name you want to use]", "value")
    /// </summary>

    public override FaucetSettings Settings {
        get {
            return new FaucetSettings("https://fly-dash.com/") {
                new FaucetSetting(){Name="Email",Display="Email",Type=EditorType.TextBox,Required=true},
                new FaucetSetting(){Name="Password",Display="Password",Type=EditorType.Password,Required=true},
		new FaucetSetting(){Name="FaucetClaim",Display="FaucetClaim",Type=EditorType.CheckBox,Default=true},
		//insert user settings here
                //new FaucetSetting {
                //Name = "Name of your setting",
                //Display = "Display shown in Faucet Collector",
                //Type = EditorType.TextBox | EditorType.Password | EditorType.CheckBox | EditorType.Wallet | EditorType.Numeric | EditorType.ComboBox | EditorType.CheckComboBox,
                //Required = true | false,
                //Default = "Optionally a default value" | true | false | null.
                //Items = new List<string> { "item1", "item2" } (only valid for ComboBox or CheckComboBox)
                //}
            };
        }
    }

//============================================================//
//the number of "successes" in the script - when are finished  
//============================================================//

    public override void Start() {
	ad=false;		
	//Title that shows in the browser. Is used to identify and close popup windows
        Title = "Fly-Dash.com";
        
	//After we did try to claim on the faucet we search for these elements to determine if it was a success or a fail
        SuccessXPath = "//*"; //div[@id='btc-balance']
        FailXPath = "//*"; //*[text()='']

        //Let Faucet Collector start up everything
        base.Start();
    }

//============================================================//
//the number of "successes" in the script - when are finished  
//============================================================//
  
    bool ad;

    public override int DoInit() {
	//Let Faucet Collector continue.
        return base.DoInit();
    }

//==================//
//save Login Cookies 
//==================//

    public override bool IsLoggedIn() {
        //In this case we check for en element with the class "loggedIn"
	return ElementByXPath("//a[@href='/logout']") != null;
	//return true;
    }

//==================//
//save Login Cookies 
//==================//
    /// <summary>
    /// This method gets called if IsLoggedIn returned false, right before the DoLogin method is called.
    /// </summary>

    public override int BeforeLogin() {
        //This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.BeforeLogin();
    }

//========//
//DoLogin
//========//
    public override int DoLogin() {
        var ExitButton = ElementByXPath ("//a[@href='/logout']");

        //if i NOT Login - go to Login Page
	if (!IsVisible(ExitButton)) {
            GoToUrl("https://fly-dash.com/");
            Wait();
	    Wait(2);
            var StartOpenLogin = ElementByXPath("//li/a[@href='#mySignin']");
	    
            if (IsVisible(StartOpenLogin)) { 
        	Click(StartOpenLogin);
            }
            Wait(2);
            
            if (IsVisible(ElementByXPath ("//div[@id='mySignin']//input[@type='email']") )) {
       		var box_user = ElementByXPath("//div[@id='mySignin']//input[@type='email']");
	        SetText(box_user, GetSetting("Email"));
            }
            Wait(2);

            if (IsVisible(ElementByXPath ("//div[@id='mySignin']//input[@type='password']") )) {
                var box_pass = ElementByXPath("//div[@id='mySignin']//input[@type='password']");
       		SetText(box_pass, GetPassword("Password"));
            }
            Wait(4);
            
            if (IsVisible(ElementByXPath ("//button[@type='submit']") )) {
       		var ButtonLog = ElementByXPath("//button[@type='submit']");
                Click(ButtonLog);
            }
            Wait(2);
            Recaptcha_Function (); //call
            Wait();
        } // end ExitButton

        return base.DoLogin();
    }

//========//
//DoLogin
//========//

//==========//
//AfterLogin
//=========//

    public override int AfterLogin() {
	//This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.AfterLogin();
    }

//=============//
//GetFaucetWaitTime
//=============//

    public override int GetFaucetWaitTime() {
    	if(ad) {
            ad=false;
            //solve the problem in start - after he return to script again
            //return GetWaitSetting();
            GoToUrl("https://fly-dash.com/free");
            var WaitTimerText = ElementByXPath("//span[@id='utimer']");
            
            if (IsVisible(WaitTimerText)) {
       		Log("FaucetClaim: WaitTimerText apper");
      		int min,sec;
	        min = Convert.ToInt32(WaitTimerText.Text.Trim().Replace("m.", "").Replace("s.", "").Split(' ')[0])*60;
       		sec = Convert.ToInt32(WaitTimerText.Text.Trim().Replace("m.", "").Replace("s.", "").Split(' ')[1]);
       		return min+sec;
            }
		
            if (!IsVisible(WaitTimerText)) {
       		return GetWaitSetting();
            }
	}//end ad
	//let Faucet Collector continue.
   	return base.GetFaucetWaitTime();
    }

    public override int BeforeSolveCaptcha() {
        //This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.BeforeSolveCaptcha();
    }

    public override int DoSolveCaptcha() {
        //This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.DoSolveCaptcha();
    }

    public override int AfterSolveCaptcha() {
        //This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.AfterSolveCaptcha();
    }

    public override int BeforeSolveFaucet() {
        //This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.BeforeSolveCaptcha();
    }

//=============//
//DoSolveFaucet
//=============//

    public override int DoSolveFaucet() {
        //=============//
	//FaucetClaim
      	//=============//

     	if (GetBoolSetting("FaucetClaim")) {
            GoToUrl("https://fly-dash.com/free");
            var WaitTimerText = ElementByXPath("//span[@id='utimer']");
            
            if (IsVisible(WaitTimerText)) {
       		Log("FaucetClaim: WaitTimerText apper");
        	int min,sec;
       		min = Convert.ToInt32(WaitTimerText.Text.Trim().Replace("m.", "").Replace("s.", "").Split(' ')[0])*60;
       		sec = Convert.ToInt32(WaitTimerText.Text.Trim().Replace("m.", "").Replace("s.", "").Split(' ')[1]);
       		return min+sec;
            }
            
            if (!IsVisible(WaitTimerText)) {
      		var FreeDashStart = ElementByXPath("//button[contains(@data-callback,'onSubmit')]");
       		
                if (IsVisible(FreeDashStart)) {
                    //GoToUrl("https://fly-dash.com/news");
                    Click(FreeDashStart);
                    Log("FreeDashStart");
                    Wait();
                    Recaptcha_Function ();
                    //call
                    Wait();
                    Wait(4);

                    /*
                    var ContinueReading = ElementByXPath("//article[*]//a[contains(text(),'Continue reading')]");
                    if (IsVisible(ContinueReading)) {
                        Log("ContinueReading");
                        Click(ContinueReading);
                    }
                    */

                    var Roll_2_Button = ElementByXPath("//button[contains(@onclick,'roll') ]");
                    if (IsVisible(Roll_2_Button)) {
                        Recaptcha_Function ();
                        //call
                        Log("Roll_2_Button");
                        Click(Roll_2_Button);
                    }
                    Wait(2);
                    var SuccessMassage = ElementByXPath("//h3[@id='info']");
                    if (IsVisible(SuccessMassage)) {
                        Log(SuccessMassage.Text);
                        ad=true;
                    }
                    Wait(2);
                } //end FreeDashStart
            } //end WaitTimerText
        } //end FaucetClaim
        return GetWaitSetting();
        //This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.DoSolveFaucet();
    }

    public override int AfterSolveFaucet() {
        //This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.AfterSolveFaucet();
    }

/// <summary>
/// This method gets called in the end after the BeforeSolveFaucet/DoSolveFaucet and AfterSolveFaucet methods were done.
/// The base.CheckFaucetResult will try to find a visible element on the page using the XPath from SuccessXPath and FailXPath (see the Start method)
/// These properties should contain XPath expressions to find certain elements on the page.
/// For example if it finds one of the elements from the SuccessXPath, and it is visible, then it will flag the claim attempt as a success.
/// Or if it finds one of the elements from the FailXPath, and it is visible, then it will flag the claim attempt as a failure.
/// </summary>

    public override int CheckFaucetResult() {
        //This faucet has nothing to do here. We will let Faucet Collector handle it.
        return base.CheckFaucetResult();
    }

//=================//
//Recaptcha_Function
//=================//

    public int Recaptcha_Function() {
        var RecaptchaOpen_normal = ElementByXPath ("//form[@id='rollform']");
	if (IsVisible(RecaptchaOpen_normal)) {
            var result = DoSolveCaptcha();
            if (result > 0) {
                return Fail("fail not solve");
                //return to solve again - if something wrong
            }
            Wait();
	}
        var RecaptchaOpen_invisible = ElementByXPath ("//iframe[contains(@src,'google.com/recaptcha/api2/bframe?hl')]");
        if (IsVisible(RecaptchaOpen_invisible)) {
            //SolveCaptcha if apper
            var result = base.DoSolveCaptcha();
            RecaptchaUtility utility = new RecaptchaUtility(this);
            utility.DoSolve();
            if (result > 0) {
               	return Fail("Fail solving captcha");
            }
        }
	return 0;
    }//end VOID_Template_Function
}//end public class

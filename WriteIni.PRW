//Bibliotecas
#Include "totvs.ch"

/*/{Protheus.doc} User Function WriteIni
Edita arquivos appserver.ini em lote.
@type Function
@author William Correia Silva
@since 08/05/2024
@see https://tdn.totvs.com/display/tec/TRpc;https://tdn.totvs.com/display/tec/WritePProString;https://tdn.totvs.com/display/tec/DeleteKeyINI
@obs 
Objetivo dessa função é utilizar o proprio protheus para alterar os arquivos appserver.ini, principalmente em base cloud totvs, onde não tem acesso aos arquivos via sistema operacional.

Exemplo do arquivo /writeIni.json
{
    "SCHEDULE": [
        {
            "environment": "env_schd",
            "ip": "192.168.2.11",
            "port": 11101
        },
        {
            "environment": "env_schd",
            "ip": "192.168.2.11",
            "port": 11102
        }
    ],
    "REST": [
        {
            "environment": "env_rest",
            "ip": "192.168.2.13",
            "port": 11301
        },
        {
            "environment": "env_rest",
            "ip": "192.168.2.13",
            "port": 11302
        }
    ],
    "SLAVE": [
        {
            "environment": "env_slave",
            "ip": "192.168.2.12",
            "port": 11201
        },
        {
            "environment": "env_slave",
            "ip": "192.168.2.12",
            "port": 11202
        }
    ]
}
/*/

User Function WriteIni()
	Local aTipos      := {"SLAVE", "SCHEDULE", "REST"} //se alterar aqui tambem alterar no json do arquivo.
	Local cJson       := MemoRead("/writeIni.json") //arquivo salvo na protheus_data.

	Private cChave    := SPACE(120)
	Private cConteudo := SPACE(120)
	Private cDel      := "Não"
	Private cSecao    := SPACE(120)
	Private cTipo     := ""
	Private jServers  := JsonObject():New()

	If EMPTY(cJson)
		FWAlertError("Não foi encontrado arquivo: /writeIni.json ")
		Return
	EndIf

	If jServers:fromjson(cJson) != Nil
		FWAlertError("Arquivo json invalido")
		Return
	EndIf

	DEFINE MSDIALOG oDlg FROM 0,0 TO 400,500 PIXEL TITLE "Editor AppServer.ini"

	oSay   := tSay():New(01, 10, {||"Sessão"}                                , oDlg,    ,    ,   , ,  , .T.)
	oTGet1 := TGet():New(10, 10, {|u| Iif(PCount()>0,cSecao:=u,cSecao)}      , oDlg, 200, 010, "", , 0,    , , .F., , .T., , .F., , .F., .F., , .F., .F., , cSecao   , , , ,)

	oSay   := tSay():New(26, 10, {||"Chave"}                                 , oDlg,    ,    ,   , ,  , .T.)
	oTGet2 := TGet():New(35, 10, {|u| Iif(PCount()>0,cChave:=u,cChave)}      , oDlg, 200, 010, "", , 0,    , , .F., , .T., , .F., , .F., .F., , .F., .F., , cChave   , , , ,)

	oSay   := tSay():New(51, 10, {||"Conteudo"}                              , oDlg,    ,    ,   , ,  , .T.)
	oTGet3 := TGet():New(60, 10, {|u| Iif(PCount()>0,cConteudo:=u,cConteudo)}, oDlg, 200, 010, "", , 0,    , , .F., , .T., , .F., , .F., .F., , .F., .F., , cConteudo, , , ,)

	oSay   := tSay():New(76, 10, {||"Delete"}   , oDlg,    ,    ,     , ,  , .T.)
	oCmbTip := TComboBox():New(85,10,{|u|if(PCount()>0,cDel:=u,cDel)},{"Não","Sim"},100,10,oDlg,,{||/*On Change*/},,,,.T.,,,,,,,,,'cDel')

	oSay   := tSay():New(100, 10, {||"Tipo"}   , oDlg,    ,    ,     , ,  , .T.)
	oCmbTip := TComboBox():New(109,10,{|u|if(PCount()>0,cTipo:=u,cTipo)},aTipos,100,10,oDlg,,{||/*On Change*/},,,,.T.,,,,,,,,,'cTipo')

	oBtnOk := tButton():New(130, 10, "OK"      , oDlg, {||(lRet := .T., lCont := .T., FwMsgRun(, {|| Executa() } , "Aguarde..." , "Editando arquivos..." ) )}, 30, 12, , , , .T.) //  Ok
	oBtnCa := tButton():New(150, 10, "Cancelar", oDlg, {||(lRet := .F., lCont := .F., oDlg:End() )}, 30, 12, , , , .T.) // Anular

	ACTIVATE MSDIALOG oDlg CENTERED

Return

/*/{Protheus.doc} Static Function Executa
Executa ações preenchida na tela.
@type Function
@author William Correia Silva
@since 08/05/2024
/*/
Static Function Executa()

	Local cRpcServer := ""
	Local nPorta     := 0
	Local cEnv 		 := ""
	Local nTimeOut   := 10
	Local cArqIni    := ""
	Local nSrv       := 0
	Local oServer
	Local cBuilds := ""
	Local aServer   := jServers[cTipo]

	cConteudo := ALLTRIM(cConteudo)
	cChave    := ALLTRIM(cChave)
	cSecao    := ALLTRIM(cSecao)

	FOR nSrv := 1 TO LEN(aServer)

		cRpcServer := aServer[nSrv]['ip']
		nPorta     := aServer[nSrv]['port']
		cEnv 	   := aServer[nSrv]['environment']

		oServer := TRPC():New(cEnv)

		// Tentando se conectar
		If oServer:Connect( cRpcServer, nPorta , nTimeOut)

			cArqIni := oServer:CallProc("GetAdv97")

			If cDel == "Sim"
				IF !oServer:CallProc("DeleteKeyIni",cSecao, cChave, cArqIni )
					FWAlertError("Servidor: " + cRpcServer + ":" +CValToChar(nPorta),"Falha editar ini")
				EndIF
			Else
				IF !oServer:CallProc("writePProString",cSecao, cChave, cConteudo, cArqIni )
					FWAlertError("Servidor: " + cRpcServer + ":" +CValToChar(nPorta),"Falha editar ini")
				EndIF
			EndIf

			//Aproveito para conferir data, hora e build dos appservers se estão tudo iguais...
			cBuilds += cRpcServer + ":" + CValToChar(nPorta) + " " + DTOC(oServer:CallProc("DATE")) + " - " + oServer:CallProc("TIME") + " - " +  oServer:CallProc("GetBuild") + CRLF

			oServer:Disconnect()
		Else
			FWAlertError("Servidor: " + cRpcServer + " Port: " + CVALTOCHAR(nPorta),"Falha na conexão")
		EndIf

	NEXT nSrv

	cChave    := PADR(cChave,120)
	cConteudo := PADR(cConteudo,120)
	cDel      := "Não"
	cSecao    := PADR(cSecao,120)

	freeobj(oServer)
	oServer := Nil

	HS_MsgInf(cBuilds, "WriteIni", "Concluido")
Return


surface.CreateFont( "SpectatorScoreboardObjHunt",
{
	font = "Helvetica",
	size = 20,
	weight = 30,
	antialias = true,
	outline = false,
})
surface.CreateFont( "ScoreboardObjHunt",
{
	font = "Helvetica",
	size = 35,
	weight = 30,
	antialias = true,
	outline = false,
})
surface.CreateFont( "PlayerObjHunt",
{
	font = "Helvetica",
	size = 15,
	weight = 20,
	antialias = true,
	outline = false,
})
--
-- This defines a ScoreboardObjHunt panel type for the player row. The player row is given a player
-- and then from that point on it pretty much looks after itself. It updates player info
-- in the think function, and removes itself when the player leaves the server.
--
local PADDING = 3
local PLAYER_LINE = 
{
	Init = function( self )

		self.AvatarButton = self:Add( "DButton" )
		self.AvatarButton:Dock( LEFT )
		self.AvatarButton:SetSize( 16, 16 )
		self.AvatarButton.DoClick = function() self.Player:ShowProfile() end

		self.Avatar = vgui.Create( "AvatarImage", self.AvatarButton )
		self.Avatar:SetSize( 16, 16 )
		self.Avatar:SetMouseInputEnabled( false )		

		self.Name = self:Add( "DLabel" )
		self.Name:Dock( FILL )
		self.Name:SetFont( "PlayerObjHunt" )
		self.Name:DockMargin( 8, 0, 0, 0 )

		self.Mute		= self:Add( "DImageButton" )
		self.Mute:SetSize( 16, 16 )
		self.Mute:Dock( RIGHT )

		self.Ping		= self:Add( "DLabel" )
		self.Ping:Dock( RIGHT )
		self.Ping:SetWidth( ScrW()/40 )
		self.Ping:SetFont( "PlayerObjHunt" )
		self.Ping:SetContentAlignment( 5 )

		self.Deaths		= self:Add( "DLabel" )
		self.Deaths:Dock( RIGHT )
		self.Deaths:SetWidth( ScrW()/40 )
		self.Deaths:SetFont( "PlayerObjHunt" )
		self.Deaths:SetContentAlignment( 5 )

		self.Kills		= self:Add( "DLabel" )
		self.Kills:Dock( RIGHT )
		self.Kills:SetWidth( ScrW()/40 )
		self.Kills:SetFont( "PlayerObjHunt" )
		self.Kills:SetContentAlignment( 5 )

		self:Dock( TOP )
		self:DockPadding( PADDING, PADDING, PADDING, PADDING )
		self:SetHeight( 16 + 3*2 )
		
	end,
	
	Setup = function( self, pl )
		
		self.Player = pl

		self.Avatar:SetPlayer( pl )
		self.Name:SetText( pl:Nick() )

		self:Think(self )

	end,

	Think = function( self )

		if ( !IsValid( self.Player ) )then
			self:Remove()
			return
		end

		if ( self.NumKills == nil || self.NumKills != self.Player:Frags() ) then
			self.NumKills	=	self.Player:Frags()
			self.Kills:SetText( self.NumKills )
		end

		if ( self.NumDeaths == nil || self.NumDeaths != self.Player:Deaths() ) then
			self.NumDeaths	=	self.Player:Deaths()
			self.Deaths:SetText( self.NumDeaths )
		end

		if ( self.NumPing == nil || self.NumPing != self.Player:Ping() ) then
			self.NumPing	=	self.Player:Ping()
			self.Ping:SetText( self.NumPing )
		end

		--
		-- Change the icon of the mute button based on state
		--
		if ( self.Muted == nil || self.Muted != self.Player:IsMuted() ) then

			self.Muted = self.Player:IsMuted()
			if ( self.Muted ) then
				self.Mute:SetImage( "icon16/sound_mute.png" )
			else
				self.Mute:SetImage( "icon16/sound.png" )
			end

			self.Mute.DoClick = function() self.Player:SetMuted( !self.Muted ) end

		end
		
		--
		-- Connecting players go at the very bottom
		--
		/*
		if ( self.Player:Team() == TEAM_CONNECTING ) then
			self:SetZPos( 2000 )
		end
		*/
		--
		-- This is what sorts the list. The panels are docked in the z order, 
		-- so if we set the z order according to kills they'll be ordered that way!
		-- Careful though, it's a signed short internally, so needs to range between -32,768k and +32,767
		--
		self:SetZPos( -(self.Player:Team()*100) +
		(
			self.NumKills * -ScrW()/40) +
			self.NumDeaths +
			math.min(string.byte(self.Player:Nick(), -1)/2, 99)
		)
	end,

	Paint = function( self, w, h )

		if ( !IsValid( self.Player ) ) then
			return
		end

		--
		-- We draw our background a different colour based on the status of the player
		--
		if ( self.Player:Team() == TEAM_PROPS) then
			surface.SetDrawColor( OFF_COLOR )
			surface.DrawRect( 0, 0, w, h)
			surface.SetDrawColor(PANEL_BORDER)
			surface.DrawOutlinedRect( 0, 0, w, h)
			return
		end
		if ( self.Player:Team() == TEAM_HUNTERS) then
			surface.SetDrawColor( Color(85,85,85) )
			surface.DrawRect( 0, 0, w, h)
			surface.SetDrawColor(PANEL_BORDER)
			surface.DrawOutlinedRect( 0, 0, w, h)
			return
		end

		-- all other teams
		draw.RoundedBox( 4, 0, 0, w, h, Color( 127, 127, 127, 127 ) )
		return

	end,
}

--
-- Convert it from a normal table into a Panel Table based on DPanel
--
PLAYER_LINE = vgui.RegisterTable( PLAYER_LINE, "DPanel" )

local HUNTERS_BOARD = 
{
	Init = function( self )
		
		self:SetSize(ScrW()/6, ScrH()/2 )//4
		
		self.Header = self:Add( "Panel" )
		self.Header:Dock( TOP )
		self.Header:SetHeight( 40 )
		
		self.Header.Paint = function(self,w,h)
		surface.SetDrawColor( TEAM_HUNTERS_COLOR )
		surface.DrawRect(0,0,w,h)
		end
		
		self.Name = self.Header:Add( "DLabel" )
		self.Name:Dock( TOP )
		self.Name:SetHeight( 40 )
		self.Name:SetText("")
		
		self.Name.Paint = function(self,w,h)
		
		surface.SetFont( "ScoreboardObjHunt" )
		surface.SetTextColor( Color( 255,255,255,255 ) )
		
		local text = "Hunters"
		local tw, th = surface.GetTextSize( text )
		
		surface.SetTextPos( w/2 - tw/2, h/2 - th/2 )
		surface.DrawText( text )
		
		
		surface.SetDrawColor(PANEL_BORDER)
		surface.DrawOutlinedRect( 0, 0, w, h)
		
		end
		
		--self.NumPlayers = self.Header:Add( "DLabel" )
		--self.NumPlayers:SetFont( "ScoreboardObjHunt" )
		--self.NumPlayers:SetTextColor( Color( 255, 255, 255, 255 ) )
		--self.NumPlayers:SetPos( 0, 100 - 30 )
		--self.NumPlayers:SetSize( 300, 30 )
		--self.NumPlayers:SetContentAlignment( 4 )

		self.Scores = self:Add( "DScrollPanel" )
		self.Scores:Dock( FILL)//fill

	end,
	
	PerformLayout = function( self )
		
		self:Dock(LEFT)
		self:DockMargin(638,ScrH()/7,0,0)
		
	end,

	Paint = function( self, w, h )
		w = ScrW()/6
		h = ScrH()/2
		
		surface.SetDrawColor( PANEL_FILL )
		surface.DrawRect( 0, 0, w, h)
		surface.SetDrawColor(PANEL_BORDER)
		surface.DrawOutlinedRect( 0, 0, w, h)
	
	end,

	Think = function( self )
		
		--
		-- Loop through each player, and if one doesn't have a score entry - create it.
		--
		local plyrs = player.GetAll()
		
		for id, pl in pairs( plyrs ) do
		
		if(pl:Team()==TEAM_HUNTERS) then
			
			if ( IsValid( pl.ScoreEntry ) ) then continue end
			
			pl.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, pl.ScoreEntry )
			pl.ScoreEntry:Setup( pl )
			
			self.Scores:AddItem( pl.ScoreEntry )
		
		else if(IsValid(pl.ScoreEntry)) then
			
			if(pl.ScoreEntry:HasParent(self.Scores)) then
			
			pl.ScoreEntry:Remove()
		
			end
		end
		end
		end
	end,
}

HUNTERS_BOARD = vgui.RegisterTable( HUNTERS_BOARD, "EditablePanel" )

local PROPS_BOARD = 
{
	Init = function( self )
		
		self:SetSize(ScrW()/6, ScrH()/2 )
		
		self.Header = self:Add( "Panel" )
		self.Header:Dock( TOP )
		self.Header:SetHeight( 40 )
		
		self.Header.Paint = function(self,w,h)
		surface.SetDrawColor( TEAM_PROPS_COLOR )
		surface.DrawRect(0,0,w,h)
		end
		
		self.Name = self.Header:Add( "DLabel" )
		self.Name:Dock( TOP )
		self.Name:SetHeight( 40 )
		self.Name:SetText("")
		
		self.Name.Paint = function(self,w,h)
		
		surface.SetFont( "ScoreboardObjHunt" )
		surface.SetTextColor( Color( 255,255,255,255 ) )
		
		local text = "Props"
		local tw, th = surface.GetTextSize( text )
		
		surface.SetTextPos( w/2 - tw/2, h/2 - th/2 )
		surface.DrawText( text )
		
		surface.SetDrawColor( PANEL_BORDER )
		surface.DrawOutlinedRect( 0, 0, w, h)
		
		end
		
		--self.NumPlayers = self.Header:Add( "DLabel" )
		--self.NumPlayers:SetFont( "ScoreboardObjHunt" )
		--self.NumPlayers:SetTextColor( Color( 255, 255, 255, 255 ) )
		--self.NumPlayers:SetPos( 0, 100 - 30 )
		--self.NumPlayers:SetSize( 300, 30 )
		--self.NumPlayers:SetContentAlignment( 4 )

		self.Scores = self:Add( "DScrollPanel" )
		self.Scores:Dock(FILL)//fill

	end,

	PerformLayout = function( self )

		
		self:Dock(RIGHT)
		self:DockMargin(0,ScrH()/7,638,0)//-100
		
	end,

	Paint = function( self, w, h )
		w = ScrW()/6
		h = ScrH()/2
		
		surface.SetDrawColor( PANEL_FILL )
		surface.DrawRect( 0, 0, w, h)
		surface.SetDrawColor(PANEL_BORDER)
		surface.DrawOutlinedRect( 0, 0, w, h)

	end,

	Think = function( self, w, h )

		--
		-- Loop through each player, and if one doesn't have a score entry - create it.
		--
		
		local plyrs = player.GetAll()
		
		for id, pl in pairs( plyrs ) do
		
		if(pl:Team()==TEAM_PROPS) then
			
			if ( IsValid( pl.ScoreEntry ) ) then continue end
			
			pl.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, pl.ScoreEntry )
			pl.ScoreEntry:Setup( pl )
			
			self.Scores:AddItem( pl.ScoreEntry )
		
		else if(IsValid(pl.ScoreEntry)) then
		
			if(pl.ScoreEntry:HasParent(self.Scores)) then
		
			pl.ScoreEntry:Remove()
		
			end
		end
		end
		end
	end,

}

PROPS_BOARD = vgui.RegisterTable( PROPS_BOARD, "EditablePanel" )

local SPECS_BOARD =
{
	Init = function( self )
		
		self:SetSize(ScrW()/3, ScrH()/6)
		
		self.Header = self:Add("Panel")
		self.Header:SetSize(self:GetWide(),ScrW()/40)
		
		self.Name = self.Header:Add("DLabel")
		self.Name:SetFont("ScoreboardObjHunt")
		self.Name:SetTextColor( Color( 255, 255, 255, 255 ) )
		self.Name:SetSize(142,40)
		self.Name:Center()
		self.Name:SetText("Spectators")
		
		self.Spec_Players = self:Add("DLabel")
		self.Spec_Players:SetFont("SpectatorScoreboardObjHunt")
		self.Spec_Players:SetTextColor( Color( 255, 255, 255, 255 ) )
		self.Spec_Players:SetMultiline(true)
		self.Spec_Players:MoveBelow(self.Header)
		
	end,
	
	PerformLayout = function( self )

		self:Center()
		self:AlignBottom(math.floor(ScrH()/5.2))
		
	end,
	
	/*Paint = function( self, w, h )
		w=ScrW()/3
		h=ScrH()/6
		surface.SetDrawColor( PANEL_FILL )
		surface.DrawRect( 0, 0, w, h)
		surface.SetDrawColor(PANEL_BORDER)
		surface.DrawOutlinedRect( 0, 0, w, h)

	end,*/
	
	Think = function( self )
	
	Spectators=""
	
	local plyrs=player.GetAll()
	
	for id, pl in pairs ( plyrs ) do
		
		
		if(pl:Team()==0||pl:Team()==1002) then
			
			if(Spectators:find(pl:Nick())==nil) then
			
			Spectators=Spectators..pl:Nick()..","
			self.Spec_Players:SetText(Spectators)
			self.Spec_Players:SizeToContents()
			if(self.Spec_Players:GetWide()+30>=self:GetWide()) then
			self.Spec_Players:SetWidth(self:GetWide())
			Spectators=Spectators.."\n"
			self.Spec_Players:SetWidth(self:GetWide())
			end
			else
			
			continue
			
			end
		
		else if(Spectators:find(pl:Nick())!=nil)  then
		
		Spectators:gsub(pl:Nick(),"")
		
		end
	end
	end
	self.Spec_Players:SetText(Spectators)
	self.Spec_Players:SizeToContents()
	
	
	end,
}

SPECS_BOARD = vgui.RegisterTable( SPECS_BOARD, "EditablePanel" )	
	
--[[---------------------------------------------------------
   Name: gamemode:ScoreboardShow( )
   Desc: Sets the scoreboard to visible
-----------------------------------------------------------]]
function GM:ScoreboardShow()

	if ( !IsValid( h_Scoreboard )&& !IsValid(p_Scoreboard)&&!IsValid(s_Scoreboard)) then
		
		h_Scoreboard = vgui.CreateFromTable( HUNTERS_BOARD )
		p_Scoreboard = vgui.CreateFromTable( PROPS_BOARD )
		s_Scoreboard = vgui.CreateFromTable( SPECS_BOARD )
	
	end

	if ( IsValid( h_Scoreboard ) && IsValid(p_Scoreboard)) then
		h_Scoreboard:Show()
		h_Scoreboard:MakePopup()
		h_Scoreboard:SetKeyboardInputEnabled( false )
		
		p_Scoreboard:Show()
		p_Scoreboard:MakePopup()
		p_Scoreboard:SetKeyboardInputEnabled( false )
		
		s_Scoreboard:Show()
		s_Scoreboard:MakePopup()
		s_Scoreboard:SetKeyboardInputEnabled( false )
		
	end

end

--[[---------------------------------------------------------
   Name: GameMode:ScoreboardHide( )
   Desc: Hides the scoreboard
-----------------------------------------------------------]]
function GM:ScoreboardHide()

	if ( IsValid( h_Scoreboard ) && IsValid(p_Scoreboard)) then
		
		h_Scoreboard:Hide()
		p_Scoreboard:Hide()
		s_Scoreboard:Hide()
	
	end

end


--[[---------------------------------------------------------
   Name: gamemode:HUDDrawScoreBoard( )
   Desc: If you prefer to draw your scoreboard the stupid way (without vgui)
-----------------------------------------------------------]]
function GM:HUDDrawScoreBoard()

end
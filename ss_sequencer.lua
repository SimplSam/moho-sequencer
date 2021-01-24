-- -------------------------------
-- Intro
-- -------------------------------

ScriptName = "SS_Sequencer"

-- SS_Sequencer - Display/Update the timing Offset of a Layer Sequence in Moho
-- version:	MH12/13 001.0 #5101 - by Sam Cogheil (SimplSam)


--[[ ***** Licence & Warranty *****

	This work is licensed under a GNU General Public License v3.0 license
	Please see: https://www.gnu.org/licenses/gpl-3.0.en.html

	You can:
		Usage - Use/Reuse Freely
		Adapt — remix, transform, and build upon the material for any purpose, even commercially
		Share — copy and redistribute the material in any medium or format

	Adapt / Share under the following terms:
		Attribution — You must give appropriate credit, provide a link to the GPL-3.0 license, and
		indicate if changes were made. You may do so in any reasonable manner, but not in any way
		that suggests the licensor endorses you or your use.

        ShareAlike — If you remix, transform, or build upon the material, you must distribute your
        contributions under the same license as this original.

	Warranty:

		Your use of this software material is at your own risk.

		By accepting to use this material you acknowledge that Sam Cogheil / SimplSam
		("The Developer") make no warranties whatsoever - expressed or implied for the
		merchantability or fitness for a particular purpose of the software provided.

		The Developer will not be liable for any direct, indirect or consequential loss
		of actual or anticipated - data, revenue, profits, business, trade or goodwill
		that is suffered as a result of the use of the software provided.

--]]


--[[
	***** SPECIAL THANKS to:
	*    Stan (and team) @ MOHO Scripting -- http://mohoscripting.com
	*    The friendly faces @ Lost Marble Moho forum -- http://www.lostmarble.com/forum
	*****
]]

-- ----------------------------------------------------
-- Script config
-- ----------------------------------------------------

SS_Sequencer = {}

function SS_Sequencer:Name()
    return 'SS Sequencer'
end

function SS_Sequencer:Version()
    return '1.00 #5101'
end

function SS_Sequencer:UILabel()
    return 'View/Change Layer Sequence offset'
end

function SS_Sequencer:Creator()
    return 'Sam Cogheil (SimplSam)'
end

function SS_Sequencer:Description()
    return 'Display/Update the timing Offset of a Layer Sequence'
end

function SS_Sequencer:IsEnabled(moho)
    return (moho.document:CurrentDocAction() == "") -- Disable if in Action
end


-- -------------------------------
-- Dialog & Globs
-- -------------------------------

local FRAMES_MAX = 99999  -- Max number of Frames we can shift (in dialog)
local SS_Sequencer_Dialog = {}

SS_Sequencer_Dialog.UPDATE           = MOHO.MSG_BASE
SS_Sequencer_Dialog.UPDATE_OFFSETREL = MOHO.MSG_BASE+1
SS_Sequencer_Dialog.UPDATE_STARTABS  = MOHO.MSG_BASE+2
SS_Sequencer_Dialog.UPDATE_PREV      = MOHO.MSG_BASE+3
SS_Sequencer_Dialog.UPDATE_NEXT      = MOHO.MSG_BASE+4
SS_Sequencer_Dialog.UPDATE_RESET     = MOHO.MSG_BASE+5

SS_Sequencer.docStartFrame     = 1
SS_Sequencer.parentOffsetRel   = 0
SS_Sequencer.frameOffsetRel    = 0
SS_Sequencer.frameOffsetOld    = 0
SS_Sequencer.frameStartAbs     = 1

function SS_Sequencer_Dialog:new(moho)
    local d = LM.GUI.SimpleDialog("Sequence Offset - layer  [ " .. moho.layer:Name() .. " ]", SS_Sequencer_Dialog)
    local l = d:GetLayout()
    d.moho = moho
    l:PushH()
        l:PushV()
            l:AddChild(LM.GUI.StaticText('Start Frame'), LM.GUI.ALIGN_LEFT)
            l:AddChild(LM.GUI.Divider(false), LM.GUI.ALIGN_FILL)
            l:AddChild(LM.GUI.StaticText(SS_Sequencer.docStartFrame), LM.GUI.ALIGN_CENTER)
        l:Pop()

        l:AddChild(LM.GUI.StaticText('+'), LM.GUI.ALIGN_CENTER)

        l:PushV()
            l:AddChild(LM.GUI.StaticText('Parent Offset'), LM.GUI.ALIGN_LEFT)
            l:AddChild(LM.GUI.Divider(false), LM.GUI.ALIGN_FILL)
            l:AddChild(LM.GUI.StaticText(SS_Sequencer.parentOffsetRel), LM.GUI.ALIGN_CENTER)
        l:Pop()

        l:AddChild(LM.GUI.StaticText('+'), LM.GUI.ALIGN_CENTER)

        l:AddChild(LM.GUI.Divider(true), LM.GUI.ALIGN_FILL)

        l:PushV()
            l:AddChild(LM.GUI.StaticText('Layer Offset'), LM.GUI.ALIGN_CENTER)
            l:AddChild(LM.GUI.Divider(false), LM.GUI.ALIGN_FILL)
            l:PushH()
                l:AddChild(LM.GUI.Button('<', SS_Sequencer_Dialog.UPDATE_PREV), LM.GUI.ALIGN_CENTER)
                d.frameOffsetRel = LM.GUI.TextControl(48, '000', self.UPDATE_OFFSETREL, LM.GUI.FIELD_INT)
                l:AddChild(d.frameOffsetRel, LM.GUI.ALIGN_CENTER)
                l:AddChild(LM.GUI.Button('>', SS_Sequencer_Dialog.UPDATE_NEXT), LM.GUI.ALIGN_BOTTOM)
            l:Pop()
        l:Pop()

        l:AddChild(LM.GUI.Divider(true), LM.GUI.ALIGN_FILL)

        l:AddChild(LM.GUI.StaticText('='), LM.GUI.ALIGN_CENTER)

        l:PushV()
            l:AddChild(LM.GUI.StaticText('Layer Start Frame'), LM.GUI.ALIGN_CENTER)
            l:AddChild(LM.GUI.Divider(false), LM.GUI.ALIGN_FILL)
            d.frameStartAbs = LM.GUI.TextControl(48, '000', self.UPDATE_STARTABS, LM.GUI.FIELD_INT)
            l:AddChild(d.frameStartAbs, LM.GUI.ALIGN_CENTER)
        l:Pop()
    l:Pop() --H

    l:AddChild(LM.GUI.Divider(false), LM.GUI.ALIGN_FILL)

    l:PushH(LM_ALIGN_RIGHT, 20)
        l:AddChild(LM.GUI.StaticText('* [OK] to Confirm.  [Cancel] to UNDO changes!  [Reset] to zero Offset'), LM.GUI.ALIGN_LEFT)
        l:AddChild(LM.GUI.Divider(true), LM.GUI.ALIGN_FILL)
        l:AddChild(LM.GUI.Button('Reset', SS_Sequencer_Dialog.UPDATE_RESET), LM.GUI.ALIGN_RIGHT)
    l:Pop()
    return d
end

function SS_Sequencer_Dialog:UpdateWidgets()
    self.frameOffsetRel:SetValue(SS_Sequencer.frameOffsetRel)
    self.frameStartAbs:SetValue(SS_Sequencer.frameStartAbs)
end

function SS_Sequencer_Dialog:HandleMessage(what)
    local function setFrameOffsetRel(iOffset)
        self.frameOffsetRel:SetValue(iOffset)
        self:Validate(self.frameOffsetRel, -FRAMES_MAX, FRAMES_MAX)
        self.frameStartAbs:SetValue(SS_Sequencer.docStartFrame + SS_Sequencer.parentOffsetRel + self.frameOffsetRel:IntValue())
        -- Dynamic timeline update
        self.moho.layer:SetTimingOffset(self.frameOffsetRel:IntValue() * -1)
        self.moho:UpdateUI()
        MOHO.Redraw()
    end

    if (what == self.UPDATE) then
        -- NOP - do nowt

    -- Relative Frame Offset updated?
    elseif (what == self.UPDATE_OFFSETREL) then
        setFrameOffsetRel(self.frameOffsetRel:IntValue())

    -- Absolute Start Frame updated?
    elseif (what == self.UPDATE_STARTABS) then
        self:Validate(self.frameStartAbs, -FRAMES_MAX, FRAMES_MAX)
        setFrameOffsetRel(self.frameStartAbs:IntValue() - SS_Sequencer.docStartFrame - SS_Sequencer.parentOffsetRel)

    -- Button Prev (Left/Down) clicked?
    elseif (what == self.UPDATE_PREV) then
        setFrameOffsetRel(self.frameOffsetRel:IntValue() - 1)

    -- Button Next (Right/Up) clicked?
    elseif (what == self.UPDATE_NEXT) then
        setFrameOffsetRel(self.frameOffsetRel:IntValue() + 1)

    -- Button Reset clicked?
    elseif (what == self.UPDATE_RESET) then
        setFrameOffsetRel(0)

    end
end

function SS_Sequencer_Dialog:OnValidate()
    if (not self:Validate(self.frameOffsetRel, -FRAMES_MAX, FRAMES_MAX)) then
        return false
    end
    if (not self:Validate(self.frameStartAbs, -FRAMES_MAX, FRAMES_MAX)) then
        return false
    end
	return true
end

function SS_Sequencer_Dialog:OnOK()
    -- NOP - Nothing doing here ...
end


-- -------------------------------
-- Main
-- -------------------------------

function SS_Sequencer:Run(moho)
    local layer                     = moho.layer
    local layerTimingOffset         = layer:TimingOffset()
    local layerTotalTimingOffset    = layer:TotalTimingOffset()
    SS_Sequencer.docStartFrame      = moho.document:StartFrame()
    SS_Sequencer.parentOffsetRel    = (layerTotalTimingOffset - layerTimingOffset) * -1
    if SS_Sequencer.parentOffsetRel == -0 then SS_Sequencer.parentOffsetRel = 0 end
    SS_Sequencer.frameOffsetRel     = layerTimingOffset * -1
    SS_Sequencer.frameOffsetOld     = layerTimingOffset
    SS_Sequencer.frameStartAbs      = (layerTotalTimingOffset * -1) + SS_Sequencer.docStartFrame

    local dlog = SS_Sequencer_Dialog:new(moho)
    if (dlog:DoModal() ~= LM.GUI.MSG_OK) then
        -- Cancelled so UNDO any changes. UI will update itself
        layer:SetTimingOffset(SS_Sequencer.frameOffsetOld)
		return false
    end
end
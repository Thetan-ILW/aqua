local aquathread = require("aqua.thread")

local image = {}

local ImageData = {}

ImageData.release = function(self)
	self.imageData:release()
	self.image:release()
end

image.newImageData = function(s)
	require("love.image")
	local status, err = pcall(love.image.newImageData, s)
	if not status then
		return
	end

	local imageData = setmetatable({}, {__index = ImageData})
	imageData.imageData = err

	if love.graphics then
		imageData.image = love.graphics.newImage(imageData.imageData)
	end

	return imageData
end

local newImageDataAsync = aquathread.async(function(s)
	local image = require("aqua.image")
	return image.newImageData(s)
end)

image.newImageDataAsync = function(s)
	local imageData = newImageDataAsync(s)
	if not imageData then return end
	if not imageData.image then
		imageData.image = love.graphics.newImage(imageData.imageData)
	end
	return setmetatable(imageData, {__index = ImageData})
end

return image

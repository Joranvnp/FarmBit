local Inventory = {}

Inventory.List = {}

function Inventory.Ajoute(pID)
    -- recherche deja dans l'inventaire
    local bTrouve = false 
    for k,v in ipairs(Inventory.List) do
        if v.id == pID then
            v.quantity = v.quantity + 1
            bTrouve = true
        end
    end
    if bTrouve == false then
        local item = {}
        item.id = pID
        item.quantity = 1
        table.insert(Inventory.List, item)
    end
    
end

function Inventory.Get(pIdX)
    if pIdX>0 and pIdX <= #Inventory.List then
        return Inventory.List[pIdX] 
    end
    return nil
end

return Inventory
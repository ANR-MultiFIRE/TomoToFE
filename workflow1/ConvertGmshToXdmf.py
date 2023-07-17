import meshio


def create_mesh(mesh, cell_type, prune_z=False):
    cells = mesh.get_cells_type(cell_type)

    cell_data = mesh.get_cell_data("gmsh:physical", cell_type)
    out_mesh = meshio.Mesh(points=mesh.points, cells={cell_type: cells}, cell_data={"name_to_read":[cell_data]})
    if prune_z:
        out_mesh.prune_z_0()
    return out_mesh

mesh3D_from_msh = meshio.read("ConcreteMultiDomain.msh")

tetra_mesh = create_mesh(mesh3D_from_msh, "tetra")
meshio.write("ConcreteMultiDomain_Tetra.xdmf", tetra_mesh)

triangle_mesh = create_mesh(mesh3D_from_msh, "triangle", prune_z=True)
meshio.write("ConcreteMultiDomain_Tri.xdmf", triangle_mesh)

